import Foundation
import StoreKit

@MainActor
final class PurchaseManager: ObservableObject {
    @Published private(set) var creditProducts: [Product] = []
    @Published private(set) var isPurchasing = false

    private let wallet: CreditWallet

    init(wallet: CreditWallet) {
        self.wallet = wallet

        Task {
            await fetchCreditProducts()
            await processUnfinishedConsumablesOnLaunch()
        }
    }

    func fetchCreditProducts() async {
        do {
            let fetched = try await Product.products(for: ProductIDs.creditProducts)
            let order = Dictionary(uniqueKeysWithValues: ProductIDs.creditProducts.enumerated().map { ($1, $0) })
            creditProducts = fetched.sorted { (order[$0.id] ?? .max) < (order[$1.id] ?? .max) }
        } catch {
            creditProducts = []
            logNonFatal(error, context: "fetch_credit_products")
        }
    }

    @discardableResult
    func purchaseCreditProduct(id productID: String) async -> Bool {
        guard ProductIDs.creditAmount(for: productID) != nil else {
            Analytics.log(.purchaseFail(productID: productID, errorDescription: "invalid_credit_product"))
            return false
        }

        let product: Product?
        if let cachedProduct = creditProducts.first(where: { $0.id == productID }) {
            product = cachedProduct
        } else {
            product = try? await Product.products(for: [productID]).first
        }
        guard let product else {
            Analytics.log(.purchaseFail(productID: productID, errorDescription: "product_not_found"))
            return false
        }

        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try Self.checkVerified(verification)
                guard ProductIDs.creditAmount(for: transaction.productID) != nil else {
                    return false
                }

                let granted = applyCreditsIfNeeded(for: transaction)
                if granted {
                    Analytics.log(.purchaseSuccess(productID: transaction.productID))
                } else {
                    Analytics.log(.purchaseFail(productID: transaction.productID, errorDescription: "credits_not_granted"))
                }
                await transaction.finish()
                return granted
            case .pending, .userCancelled:
                Analytics.log(.purchaseFail(productID: productID, errorDescription: "pending_or_cancelled"))
                return false
            @unknown default:
                Analytics.log(.purchaseFail(productID: productID, errorDescription: "unknown_purchase_result"))
                return false
            }
        } catch {
            Analytics.log(.purchaseFail(productID: productID, errorDescription: error.localizedDescription))
            logNonFatal(error, context: "purchase_credit_product")
            return false
        }
    }

    func processUnfinishedConsumablesOnLaunch() async {
        for await result in Transaction.unfinished {
            do {
                let transaction = try Self.checkVerified(result)
                guard ProductIDs.creditAmount(for: transaction.productID) != nil else {
                    continue
                }

                _ = applyCreditsIfNeeded(for: transaction)
                await transaction.finish()
            } catch {
                logNonFatal(error, context: "process_unfinished_consumable")
            }
        }
    }

    @discardableResult
    private func applyCreditsIfNeeded(for transaction: Transaction) -> Bool {
        let txID = String(transaction.id)
        guard let credits = ProductIDs.creditAmount(for: transaction.productID) else {
            return false
        }

        return wallet.addCredits(amount: credits, transactionID: txID)
    }

    private func logNonFatal(_ error: Error, context: String) {
        NSLog("PurchaseManager non-fatal (%@): %@", context, String(describing: error))
    }

    private static func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified:
            throw PurchaseError.failedVerification
        }
    }
}

private enum PurchaseError: Error {
    case failedVerification
}
