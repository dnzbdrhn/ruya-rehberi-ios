import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @EnvironmentObject private var creditWallet: CreditWallet
    @EnvironmentObject private var purchaseManager: PurchaseManager

    @State private var selectedPlan: PlanType = .premiumPlus
    @State private var selectedBillingCycle: BillingCycle = .yearly
    @State private var selectedCreditPack: CreditPack = .medium

    @State private var isSubscribing = false
    @State private var isBuyingCredits = false
    @State private var isRestoring = false

    var body: some View {
        ZStack {
            DreamBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    headerSection
                    billingSelector
                    plansSection
                    creditsSection
                    actionsSection
                }
                .padding(.horizontal, DreamLayout.screenHorizontal)
                .padding(.top, DreamLayout.screenTop)
                .padding(.bottom, DreamLayout.screenBottom)
            }
        }
        .task {
            if entitlementManager.products.isEmpty {
                await entitlementManager.fetchProducts()
            }
            if purchaseManager.creditProducts.isEmpty {
                await purchaseManager.fetchCreditProducts()
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "paywall.title"))
                .font(DreamTheme.heading(32))
                .foregroundStyle(DreamTheme.textPrimary)
                .multilineTextAlignment(.leading)

            Text(String(localized: "paywall.subtitle"))
                .font(DreamTheme.body(15))
                .foregroundStyle(DreamTheme.textMuted)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var billingSelector: some View {
        HStack(spacing: 10) {
            ForEach(BillingCycle.allCases, id: \.self) { cycle in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedBillingCycle = cycle
                    }
                } label: {
                    Text(cycle.localizedTitle)
                        .font(DreamTheme.medium(14))
                        .foregroundStyle(selectedBillingCycle == cycle ? DreamTheme.textDark : DreamTheme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(selectedBillingCycle == cycle ? DreamTheme.goldStart : DreamTheme.cardMid)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .dreamCard(cornerRadius: 18)
    }

    private var plansSection: some View {
        VStack(spacing: 12) {
            planCard(for: .premiumBasic)
            planCard(for: .premiumPlus)
        }
    }

    private func planCard(for plan: PlanType) -> some View {
        let isSelected = selectedPlan == plan

        return Button {
            withAnimation(.spring(response: 0.26, dampingFraction: 0.82)) {
                selectedPlan = plan
            }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(plan.localizedTitle)
                        .font(DreamTheme.heading(22))
                        .foregroundStyle(DreamTheme.textPrimary)

                    if plan == .premiumPlus {
                        Text(String(localized: "paywall.plan.plus.badge"))
                            .font(DreamTheme.medium(11))
                            .foregroundStyle(DreamTheme.textDark)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [DreamTheme.goldStart, DreamTheme.goldEnd],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                    }

                    Spacer(minLength: 0)

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(isSelected ? DreamTheme.goldStart : Color.white.opacity(0.65))
                }

                Text(priceText(for: plan))
                    .font(DreamTheme.medium(18))
                    .foregroundStyle(DreamTheme.goldStart)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                VStack(alignment: .leading, spacing: 7) {
                    ForEach(benefits(for: plan), id: \.self) { benefit in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(DreamTheme.goldStart)

                            Text(benefit)
                                .font(DreamTheme.body(14))
                                .foregroundStyle(DreamTheme.textMuted)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .dreamCard(cornerRadius: 22)
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(cardBorderColor(plan: plan, isSelected: isSelected), lineWidth: isSelected ? 2.2 : 1.2)
            )
            .scaleEffect(plan == .premiumPlus && isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.24, dampingFraction: 0.8), value: selectedPlan)
        }
        .buttonStyle(.plain)
    }

    private var creditsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "paywall.credits.title"))
                .font(DreamTheme.medium(16))
                .foregroundStyle(DreamTheme.textPrimary)

            Text(
                String(
                    format: String(localized: "paywall.credits.balance_format"),
                    locale: Locale.current,
                    creditWallet.balance
                )
            )
            .font(DreamTheme.body(14))
            .foregroundStyle(DreamTheme.textMuted)

            HStack(spacing: 10) {
                ForEach(CreditPack.allCases, id: \.self) { pack in
                    Button {
                        selectedCreditPack = pack
                    } label: {
                        Text(pack.localizedTitle)
                            .font(DreamTheme.medium(13))
                            .foregroundStyle(selectedCreditPack == pack ? DreamTheme.textDark : DreamTheme.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(selectedCreditPack == pack ? DreamTheme.goldStart : DreamTheme.cardMid)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .dreamCard(cornerRadius: 20)
    }

    private var actionsSection: some View {
        VStack(spacing: 8) {
            Button {
                let productID = selectedPlan.productID(for: selectedBillingCycle)
                Analytics.log(
                    .subscribeTap(
                        tier: selectedPlan.analyticsTier,
                        cycle: selectedBillingCycle.analyticsCycle,
                        productID: productID
                    )
                )
                Task { await subscribeSelectedPlan() }
            } label: {
                Text(String(localized: isSubscribing ? "paywall.button.subscribing" : "paywall.button.subscribe"))
            }
            .dreamGoldButton()
            .disabled(isSubscribing || isBuyingCredits || isRestoring)
            .opacity(isSubscribing ? 0.8 : 1)

            Button {
                Analytics.log(
                    .creditsTap(
                        packID: selectedCreditPack.packID,
                        productID: selectedCreditPack.productID
                    )
                )
                Task { await buySelectedCredits() }
            } label: {
                Text(String(localized: isBuyingCredits ? "paywall.button.buying_credits" : "paywall.button.buy_credits"))
                    .font(DreamTheme.medium(16))
                    .foregroundStyle(DreamTheme.textPrimary)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(DreamTheme.cardMid)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.white.opacity(0.24), lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(.plain)
            .disabled(isSubscribing || isBuyingCredits || isRestoring)
            .opacity(isBuyingCredits ? 0.8 : 1)

            Button {
                Analytics.log(.restoreTap)
                Task { await restorePurchases() }
            } label: {
                Text(String(localized: isRestoring ? "paywall.button.restoring" : "paywall.button.restore"))
                    .font(DreamTheme.body(13))
                    .foregroundStyle(DreamTheme.textMuted)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            .disabled(isSubscribing || isBuyingCredits || isRestoring)
        }
        .padding(.top, 2)
    }

    private func priceText(for plan: PlanType) -> String {
        let productID = plan.productID(for: selectedBillingCycle)
        if let product = entitlementManager.products.first(where: { $0.id == productID }) {
            return product.displayPrice
        }
        return String(localized: "paywall.price.loading")
    }

    private func benefits(for plan: PlanType) -> [String] {
        switch plan {
        case .premiumBasic:
            return [
                String(localized: "paywall.plan.basic.benefit.1"),
                String(localized: "paywall.plan.basic.benefit.2"),
                String(localized: "paywall.plan.basic.benefit.3")
            ]
        case .premiumPlus:
            return [
                String(localized: "paywall.plan.plus.benefit.1"),
                String(localized: "paywall.plan.plus.benefit.2"),
                String(localized: "paywall.plan.plus.benefit.3")
            ]
        }
    }

    private func cardBorderColor(plan: PlanType, isSelected: Bool) -> Color {
        if plan == .premiumPlus {
            return isSelected ? DreamTheme.goldStart : DreamTheme.goldEnd.opacity(0.8)
        }
        return isSelected ? Color.white.opacity(0.45) : Color.white.opacity(0.18)
    }

    @MainActor
    private func subscribeSelectedPlan() async {
        guard !isSubscribing else { return }
        isSubscribing = true
        defer { isSubscribing = false }

        let success = await entitlementManager.purchase(productID: selectedPlan.productID(for: selectedBillingCycle))
        if success {
            dismiss()
        }
    }

    @MainActor
    private func buySelectedCredits() async {
        guard !isBuyingCredits else { return }
        isBuyingCredits = true
        defer { isBuyingCredits = false }

        _ = await purchaseManager.purchaseCreditProduct(id: selectedCreditPack.productID)
    }

    @MainActor
    private func restorePurchases() async {
        guard !isRestoring else { return }
        isRestoring = true
        defer { isRestoring = false }

        do {
            try await AppStore.sync()
            Analytics.log(.restoreSuccess)
        } catch {
            Analytics.log(.restoreFail(errorDescription: error.localizedDescription))
            // Non-fatal: entitlements refresh still runs.
        }
        await entitlementManager.refreshEntitlements()
    }
}

private enum BillingCycle: CaseIterable {
    case monthly
    case yearly

    var localizedTitle: String {
        switch self {
        case .monthly:
            return String(localized: "paywall.billing.monthly")
        case .yearly:
            return String(localized: "paywall.billing.yearly")
        }
    }

    var analyticsCycle: String {
        switch self {
        case .monthly:
            return "monthly"
        case .yearly:
            return "yearly"
        }
    }
}

private enum PlanType: CaseIterable {
    case premiumBasic
    case premiumPlus

    var localizedTitle: String {
        switch self {
        case .premiumBasic:
            return String(localized: "paywall.plan.basic.name")
        case .premiumPlus:
            return String(localized: "paywall.plan.plus.name")
        }
    }

    var analyticsTier: String {
        switch self {
        case .premiumBasic:
            return "premiumBasic"
        case .premiumPlus:
            return "premiumPlus"
        }
    }

    func productID(for cycle: BillingCycle) -> String {
        switch (self, cycle) {
        case (.premiumBasic, .monthly):
            return ProductIDs.premiumBasicMonthly
        case (.premiumBasic, .yearly):
            return ProductIDs.premiumBasicYearly
        case (.premiumPlus, .monthly):
            return ProductIDs.premiumPlusMonthly
        case (.premiumPlus, .yearly):
            return ProductIDs.premiumPlusYearly
        }
    }
}

private enum CreditPack: CaseIterable {
    case small
    case medium
    case large

    var localizedTitle: String {
        switch self {
        case .small:
            return String(localized: "paywall.credits.pack.small")
        case .medium:
            return String(localized: "paywall.credits.pack.medium")
        case .large:
            return String(localized: "paywall.credits.pack.large")
        }
    }

    var productID: String {
        switch self {
        case .small:
            return ProductIDs.creditsSmall
        case .medium:
            return ProductIDs.creditsMedium
        case .large:
            return ProductIDs.creditsLarge
        }
    }

    var packID: String {
        switch self {
        case .small:
            return "small"
        case .medium:
            return "medium"
        case .large:
            return "large"
        }
    }
}
