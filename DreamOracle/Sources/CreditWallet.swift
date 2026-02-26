import Foundation

@MainActor
final class CreditWallet: ObservableObject {
    @Published private(set) var balance: Int

    private let defaults: UserDefaults
    private let balanceKey = "credit_balance"
    private let processedTransactionsKey = "credit_processed_transaction_ids_v1"
    private var processedTransactionIDs: Set<String>

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        balance = max(0, defaults.integer(forKey: balanceKey))
        processedTransactionIDs = Set(defaults.stringArray(forKey: processedTransactionsKey) ?? [])
    }

    func addCredits(amount: Int) {
        guard amount > 0 else { return }
        balance += amount
        persist()
    }

    @discardableResult
    func addCredits(amount: Int, transactionID: String) -> Bool {
        guard amount > 0 else { return false }
        guard !processedTransactionIDs.contains(transactionID) else { return false }

        // Persist processed ID first to avoid double-credit on interrupted app relaunch.
        processedTransactionIDs.insert(transactionID)
        persistProcessedTransactions()

        balance += amount
        persist()
        return true
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

    private func persistProcessedTransactions() {
        defaults.set(Array(processedTransactionIDs), forKey: processedTransactionsKey)
    }
}
