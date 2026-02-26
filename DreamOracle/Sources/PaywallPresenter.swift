import Foundation

@MainActor
final class PaywallPresenter: ObservableObject {
    @Published var isShowing: Bool = false
    @Published var source: PaywallSource = .interpretation

    func present(for source: PaywallSource) {
        self.source = source
        Analytics.log(.paywallShown(source: source))
        isShowing = true
    }

    func dismiss() {
        isShowing = false
    }
}

enum PaywallSource: String, CaseIterable {
    case interpretation
    case image
    case perspective
    case question
}
