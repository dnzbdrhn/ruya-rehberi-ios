import Foundation

enum ProductIDs {
    static let premiumBasicMonthly = "premium_basic_monthly"
    static let premiumBasicYearly = "premium_basic_yearly"
    static let premiumPlusMonthly = "premium_plus_monthly"
    static let premiumPlusYearly = "premium_plus_yearly"
    static let creditsSmall = "credits_small"
    static let creditsMedium = "credits_medium"
    static let creditsLarge = "credits_large"

    static let premiumBasic: Set<String> = [
        premiumBasicMonthly,
        premiumBasicYearly
    ]

    static let premiumPlus: Set<String> = [
        premiumPlusMonthly,
        premiumPlusYearly
    ]

    static let all: [String] = [
        premiumBasicMonthly,
        premiumBasicYearly,
        premiumPlusMonthly,
        premiumPlusYearly,
        creditsSmall,
        creditsMedium,
        creditsLarge
    ]

    static let creditProducts: [String] = [
        creditsSmall,
        creditsMedium,
        creditsLarge
    ]

    static func creditAmount(for productID: String) -> Int? {
        switch productID {
        case creditsSmall:
            return 5
        case creditsMedium:
            return 15
        case creditsLarge:
            return 40
        default:
            return nil
        }
    }
}
