import Foundation
import StoreKit

@MainActor
final class EntitlementManager: ObservableObject {
    @Published private(set) var currentTier: SubscriptionTier
    @Published private(set) var products: [Product] = []

    private let defaults: UserDefaults
    private let tierCacheKey = "entitlement.currentTier.v1"
    private var transactionUpdatesTask: Task<Void, Never>?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if
            let cachedTier = defaults.string(forKey: tierCacheKey),
            let resolved = SubscriptionTier(rawValue: cachedTier)
        {
            currentTier = resolved
        } else {
            currentTier = .free
        }

        transactionUpdatesTask = observeTransactionUpdates()

        Task {
            await refreshEntitlements()
        }

        Task {
            await fetchProducts()
        }
    }

    deinit {
        transactionUpdatesTask?.cancel()
    }

    func fetchProducts() async {
        do {
            let fetched = try await Product.products(for: ProductIDs.all)
            products = fetched.sorted { $0.id < $1.id }
        } catch {
            products = []
        }
    }

    func refreshEntitlements() async {
        do {
            let refreshedTier = try await resolveCurrentTierFromStoreKit()
            cache(tier: refreshedTier)
        } catch is CancellationError {
            // No-op on cancellation.
        } catch {
            logNonFatal(error, context: "refresh_entitlements")
        }
    }

    @discardableResult
    func purchase(productID: String) async -> Bool {
        let isSubscription = ProductIDs.premiumBasic.contains(productID) || ProductIDs.premiumPlus.contains(productID)
        guard isSubscription else {
            Analytics.log(.purchaseFail(productID: productID, errorDescription: "invalid_subscription_product"))
            return false
        }

        let product: Product?
        if let cachedProduct = products.first(where: { $0.id == productID }) {
            product = cachedProduct
        } else {
            product = try? await Product.products(for: [productID]).first
        }
        guard let product else {
            Analytics.log(.purchaseFail(productID: productID, errorDescription: "product_not_found"))
            return false
        }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try Self.checkVerified(verification)
                await transaction.finish()
                await refreshEntitlements()
                Analytics.log(.purchaseSuccess(productID: productID))
                return true
            case .pending, .userCancelled:
                Analytics.log(.purchaseFail(productID: productID, errorDescription: "pending_or_cancelled"))
                return false
            @unknown default:
                Analytics.log(.purchaseFail(productID: productID, errorDescription: "unknown_purchase_result"))
                return false
            }
        } catch {
            Analytics.log(.purchaseFail(productID: productID, errorDescription: error.localizedDescription))
            logNonFatal(error, context: "purchase_subscription")
            return false
        }
    }

    private func observeTransactionUpdates() -> Task<Void, Never> {
        Task { [weak self] in
            for await update in Transaction.updates {
                guard let self else { break }
                await self.handle(transactionUpdate: update)
            }
        }
    }

    private func handle(transactionUpdate: VerificationResult<Transaction>) async {
        if let transaction = try? Self.checkVerified(transactionUpdate) {
            await transaction.finish()
        }
        await refreshEntitlements()
    }

    private func resolveCurrentTierFromStoreKit() async throws -> SubscriptionTier {
        try Task.checkCancellation()
        var highestActiveTier: SubscriptionTier = .free

        for await entitlement in Transaction.currentEntitlements {
            try Task.checkCancellation()

            let transaction: Transaction
            do {
                transaction = try Self.checkVerified(entitlement)
            } catch {
                logNonFatal(error, context: "verify_current_entitlement")
                continue
            }

            guard transaction.revocationDate == nil else { continue }
            guard !transaction.isUpgraded else { continue }
            if let expirationDate = transaction.expirationDate, expirationDate < Date() {
                continue
            }

            guard let tier = SubscriptionTier.tier(for: transaction.productID) else { continue }

            if tier > highestActiveTier {
                highestActiveTier = tier
            }

            if highestActiveTier == .premiumPlus {
                return .premiumPlus
            }
        }

        return highestActiveTier
    }

    private func cache(tier: SubscriptionTier) {
        currentTier = tier
        defaults.set(tier.rawValue, forKey: tierCacheKey)
    }

    private static func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified:
            throw EntitlementError.failedVerification
        }
    }

    private func logNonFatal(_ error: Error, context: String) {
#if DEBUG
        NSLog("EntitlementManager non-fatal (%@): %@", context, String(describing: error))
#else
        _ = (error, context)
#endif
    }
}

private enum EntitlementError: Error {
    case failedVerification
}
