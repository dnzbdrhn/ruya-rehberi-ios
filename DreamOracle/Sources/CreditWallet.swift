import Foundation

@MainActor
final class CreditWallet: ObservableObject {
    @Published private(set) var balance: Int

    private let defaults: UserDefaults
    private let balanceKey = "credit_balance"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        balance = max(0, defaults.integer(forKey: balanceKey))
    }

    func addCredits(amount: Int) {
        guard amount > 0 else { return }
        balance += amount
        persist()
    }

    @discardableResult
    func spendCredits(amount: Int) -> Bool {
        guard amount > 0 else { return false }
        guard balance >= amount else { return false }
        balance -= amount
        persist()
        return true
    }

    private func persist() {
        defaults.set(balance, forKey: balanceKey)
    }
}
