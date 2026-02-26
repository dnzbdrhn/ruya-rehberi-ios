import Foundation

@MainActor
final class FeatureGate: ObservableObject {
    struct DreamUsage: Codable {
        var imageUsed: Bool = false
        var premiumPerspectiveCount: Int = 0
    }

    @Published private(set) var lastResetDate: Date
    @Published private(set) var dreamsUsedTodayForPremium: [String]
    @Published private(set) var questionsUsedToday: Int

    private let entitlementManager: EntitlementManager
    private let creditWallet: CreditWallet
    private let defaults: UserDefaults
    private let calendar: Calendar

    private var perDreamUsage: [String: DreamUsage]
    private var freeInterpretationsLifetimeUsed: Int

    private enum Keys {
        static let lastResetDate = "lastResetDate"
        static let dreamsUsedTodayForPremium = "dreamsUsedTodayForPremium"
        static let questionsUsedToday = "questionsUsedToday"
        static let perDreamUsage = "perDreamUsage"
        static let freeInterpretationsLifetimeUsed = "freeInterpretationsLifetimeUsed"
    }

    init(
        entitlementManager: EntitlementManager,
        creditWallet: CreditWallet,
        defaults: UserDefaults = .standard,
        calendar: Calendar = .autoupdatingCurrent
    ) {
        self.entitlementManager = entitlementManager
        self.creditWallet = creditWallet
        self.defaults = defaults
        self.calendar = calendar

        if let cachedDate = defaults.object(forKey: Keys.lastResetDate) as? Date {
            lastResetDate = calendar.startOfDay(for: cachedDate)
        } else {
            lastResetDate = calendar.startOfDay(for: Date())
        }

        let storedDreams = defaults.stringArray(forKey: Keys.dreamsUsedTodayForPremium) ?? []
        dreamsUsedTodayForPremium = Self.deduplicatedDreamIDs(storedDreams)
        questionsUsedToday = max(0, defaults.integer(forKey: Keys.questionsUsedToday))

        if
            let usageData = defaults.data(forKey: Keys.perDreamUsage),
            let decoded = try? JSONDecoder().decode([String: DreamUsage].self, from: usageData)
        {
            perDreamUsage = decoded
        } else {
            perDreamUsage = [:]
        }

        freeInterpretationsLifetimeUsed = max(0, defaults.integer(forKey: Keys.freeInterpretationsLifetimeUsed))

        resetDailyUsageIfNeeded()
    }

    var currentCreditBalance: Int {
        creditWallet.balance
    }

    var remainingFreeInterpretationsLifetime: Int {
        max(0, 3 - freeInterpretationsLifetimeUsed)
    }

    func canUseFreeInterpretationLifetime() -> Bool {
        resetDailyUsageIfNeeded()
        return remainingFreeInterpretationsLifetime > 0
    }

    @discardableResult
    func consumeFreeInterpretationLifetime() -> Bool {
        resetDailyUsageIfNeeded()
        guard canUseFreeInterpretationLifetime() else { return false }
        freeInterpretationsLifetimeUsed += 1
        defaults.set(freeInterpretationsLifetimeUsed, forKey: Keys.freeInterpretationsLifetimeUsed)
        return true
    }

    func canUseImage(forDreamID dreamID: String) -> Bool {
        resetDailyUsageIfNeeded()
        switch entitlementManager.currentTier {
        case .free:
            return false
        case .premiumPlus:
            return true
        case .premiumBasic:
            guard isDreamEligibleForPremium(dreamID: dreamID) else { return false }
            return !(perDreamUsage[dreamID]?.imageUsed ?? false)
        }
    }

    @discardableResult
    func consumeImage(forDreamID dreamID: String) -> Bool {
        resetDailyUsageIfNeeded()
        switch entitlementManager.currentTier {
        case .free:
            return false
        case .premiumPlus:
            return true
        case .premiumBasic:
            guard ensureDreamReservedForPremium(dreamID: dreamID) else { return false }
            var usage = perDreamUsage[dreamID] ?? DreamUsage()
            guard !usage.imageUsed else { return false }
            usage.imageUsed = true
            perDreamUsage[dreamID] = usage
            persistUsageState()
            return true
        }
    }

    func canUsePremiumPerspective(forDreamID dreamID: String) -> Bool {
        resetDailyUsageIfNeeded()
        switch entitlementManager.currentTier {
        case .free:
            return false
        case .premiumPlus:
            return true
        case .premiumBasic:
            guard isDreamEligibleForPremium(dreamID: dreamID) else { return false }
            let usage = perDreamUsage[dreamID] ?? DreamUsage()
            return usage.premiumPerspectiveCount < 2
        }
    }

    @discardableResult
    func consumePremiumPerspective(forDreamID dreamID: String) -> Bool {
        resetDailyUsageIfNeeded()
        switch entitlementManager.currentTier {
        case .free:
            return false
        case .premiumPlus:
            return true
        case .premiumBasic:
            guard ensureDreamReservedForPremium(dreamID: dreamID) else { return false }
            var usage = perDreamUsage[dreamID] ?? DreamUsage()
            guard usage.premiumPerspectiveCount < 2 else { return false }
            usage.premiumPerspectiveCount += 1
            perDreamUsage[dreamID] = usage
            persistUsageState()
            return true
        }
    }

    func canAskQuestion() -> Bool {
        resetDailyUsageIfNeeded()
        switch entitlementManager.currentTier {
        case .free:
            return false
        case .premiumPlus:
            return true
        case .premiumBasic:
            return questionsUsedToday < 2
        }
    }

    @discardableResult
    func consumeQuestion() -> Bool {
        resetDailyUsageIfNeeded()
        switch entitlementManager.currentTier {
        case .free:
            return false
        case .premiumPlus:
            return true
        case .premiumBasic:
            guard questionsUsedToday < 2 else { return false }
            questionsUsedToday += 1
            defaults.set(questionsUsedToday, forKey: Keys.questionsUsedToday)
            return true
        }
    }

    func isDreamEligibleForPremium(dreamID: String) -> Bool {
        resetDailyUsageIfNeeded()
        switch entitlementManager.currentTier {
        case .free:
            return false
        case .premiumPlus:
            return true
        case .premiumBasic:
            return dreamsUsedTodayForPremium.contains(dreamID) || dreamsUsedTodayForPremium.count < 2
        }
    }

    private func ensureDreamReservedForPremium(dreamID: String) -> Bool {
        if dreamsUsedTodayForPremium.contains(dreamID) {
            return true
        }
        guard dreamsUsedTodayForPremium.count < 2 else { return false }
        dreamsUsedTodayForPremium.append(dreamID)
        persistUsageState()
        return true
    }

    private func resetDailyUsageIfNeeded() {
        let todayStart = calendar.startOfDay(for: Date())
        let storedStart = calendar.startOfDay(for: lastResetDate)
        guard !calendar.isDate(todayStart, inSameDayAs: storedStart) else { return }

        lastResetDate = todayStart
        dreamsUsedTodayForPremium = []
        questionsUsedToday = 0
        perDreamUsage = [:]
        persistUsageState()
    }

    private func persistUsageState() {
        defaults.set(lastResetDate, forKey: Keys.lastResetDate)
        let uniqueDreamIDs = Self.deduplicatedDreamIDs(dreamsUsedTodayForPremium)
        dreamsUsedTodayForPremium = uniqueDreamIDs
        defaults.set(uniqueDreamIDs, forKey: Keys.dreamsUsedTodayForPremium)
        defaults.set(questionsUsedToday, forKey: Keys.questionsUsedToday)

        if let encodedUsage = try? JSONEncoder().encode(perDreamUsage) {
            defaults.set(encodedUsage, forKey: Keys.perDreamUsage)
        } else {
            defaults.removeObject(forKey: Keys.perDreamUsage)
        }
    }

    private static func deduplicatedDreamIDs(_ ids: [String]) -> [String] {
        var seen = Set<String>()
        var unique: [String] = []
        for id in ids where seen.insert(id).inserted {
            unique.append(id)
        }
        return unique
    }
}
