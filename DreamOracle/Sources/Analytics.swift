import Foundation

enum AnalyticsEvent {
    case paywallShown(source: PaywallSource)
    case subscribeTap(tier: String, cycle: String, productID: String)
    case creditsTap(packID: String, productID: String)
    case purchaseSuccess(productID: String)
    case purchaseFail(productID: String, errorDescription: String)
    case restoreTap
    case restoreSuccess
    case restoreFail(errorDescription: String)

    var name: String {
        switch self {
        case .paywallShown:
            return "paywall_shown"
        case .subscribeTap:
            return "subscribe_tap"
        case .creditsTap:
            return "credits_tap"
        case .purchaseSuccess:
            return "purchase_success"
        case .purchaseFail:
            return "purchase_fail"
        case .restoreTap:
            return "restore_tap"
        case .restoreSuccess:
            return "restore_success"
        case .restoreFail:
            return "restore_fail"
        }
    }

    var payload: [String: String] {
        switch self {
        case .paywallShown(let source):
            return ["source": source.rawValue]
        case .subscribeTap(let tier, let cycle, let productID):
            return ["tier": tier, "cycle": cycle, "product_id": productID]
        case .creditsTap(let packID, let productID):
            return ["pack_id": packID, "product_id": productID]
        case .purchaseSuccess(let productID):
            return ["product_id": productID]
        case .purchaseFail(let productID, let errorDescription):
            return ["product_id": productID, "error": errorDescription]
        case .restoreTap:
            return [:]
        case .restoreSuccess:
            return [:]
        case .restoreFail(let errorDescription):
            return ["error": errorDescription]
        }
    }
}

struct AnalyticsRecord: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let name: String
    let payload: [String: String]

    init(timestamp: Date = Date(), event: AnalyticsEvent) {
        self.id = UUID()
        self.timestamp = timestamp
        self.name = event.name
        self.payload = event.payload
    }
}

enum Analytics {
    private static let queue = DispatchQueue(label: "dreamoracle.analytics.queue")
    private static let defaults = UserDefaults.standard
    private static let eventsKey = "analytics_events_v1"
    private static let maxEvents = 200
    private static var events: [AnalyticsRecord] = loadPersistedEvents()

    static func log(_ event: AnalyticsEvent) {
        let record = AnalyticsRecord(event: event)

        queue.async {
            events.append(record)
            if events.count > maxEvents {
                events.removeFirst(events.count - maxEvents)
            }

            persist(events)
            NSLog("Analytics %@ %@", record.name, record.payload.description)
        }
    }

    static func recentEvents(limit: Int = 50) -> [AnalyticsRecord] {
        queue.sync {
            let count = max(0, min(limit, events.count))
            return Array(events.suffix(count)).reversed()
        }
    }

    private static func loadPersistedEvents() -> [AnalyticsRecord] {
        guard let data = defaults.data(forKey: eventsKey) else { return [] }
        return (try? JSONDecoder().decode([AnalyticsRecord].self, from: data)) ?? []
    }

    private static func persist(_ events: [AnalyticsRecord]) {
        guard let data = try? JSONEncoder().encode(events) else { return }
        defaults.set(data, forKey: eventsKey)
    }
}

