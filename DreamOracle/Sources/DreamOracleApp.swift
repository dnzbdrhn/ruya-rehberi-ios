import SwiftUI

@main
struct DreamOracleApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel = DreamInterpreterViewModel()
    @StateObject private var entitlementManager: EntitlementManager
    @StateObject private var creditWallet: CreditWallet
    @StateObject private var purchaseManager: PurchaseManager
    @StateObject private var featureGate: FeatureGate
    @StateObject private var paywallPresenter = PaywallPresenter()

    init() {
        let entitlement = EntitlementManager()
        let wallet = CreditWallet()
        _entitlementManager = StateObject(wrappedValue: entitlement)
        _creditWallet = StateObject(wrappedValue: wallet)
        _purchaseManager = StateObject(wrappedValue: PurchaseManager(wallet: wallet))
        _featureGate = StateObject(
            wrappedValue: FeatureGate(
                entitlementManager: entitlement,
                creditWallet: wallet
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
                .environmentObject(entitlementManager)
                .environmentObject(creditWallet)
                .environmentObject(purchaseManager)
                .environmentObject(featureGate)
                .environmentObject(paywallPresenter)
                .onChange(of: scenePhase) { _, newPhase in
                    guard newPhase == .active else { return }
                    Task {
                        await entitlementManager.refreshEntitlements()
                    }
                }
        }
    }
}
