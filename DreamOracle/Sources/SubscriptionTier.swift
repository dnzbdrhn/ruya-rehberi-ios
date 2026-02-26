import Foundation

enum SubscriptionTier: String, Codable, CaseIterable, Comparable {
    case free
    case premiumBasic
    case premiumPlus

    private var rank: Int {
        switch self {
        case .free:
            return 0
        case .premiumBasic:
            return 1
        case .premiumPlus:
            return 2
        }
    }

    static func < (lhs: SubscriptionTier, rhs: SubscriptionTier) -> Bool {
        lhs.rank < rhs.rank
    }

    static func tier(for productID: String) -> SubscriptionTier? {
        if ProductIDs.premiumPlus.contains(productID) {
            return .premiumPlus
        }
        if ProductIDs.premiumBasic.contains(productID) {
            return .premiumBasic
        }
        return nil
    }
}
