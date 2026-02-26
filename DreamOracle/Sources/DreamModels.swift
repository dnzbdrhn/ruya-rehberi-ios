import Foundation

enum DreamInputSource: String, Codable {
    case typed
    case voice
}

struct DreamFollowUp: Identifiable, Codable {
    let id: UUID
    let askedAt: Date
    let question: String
    let answer: String

    init(id: UUID = UUID(), askedAt: Date = Date(), question: String, answer: String) {
        self.id = id
        self.askedAt = askedAt
        self.question = question
        self.answer = answer
    }
}

struct DreamRecord: Identifiable, Codable {
    let id: UUID
    let createdAt: Date
    var title: String
    let source: DreamInputSource
    let dreamText: String
    let interpretation: String
    var previewSummary: String
    var previewImageBase64: String?
    var symbols: [String]
    var clarity: Double
    var mood: String
    var isFavorite: Bool
    var followUps: [DreamFollowUp]

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        title: String,
        source: DreamInputSource,
        dreamText: String,
        interpretation: String,
        previewSummary: String = "",
        previewImageBase64: String? = nil,
        symbols: [String] = [],
        clarity: Double = 0.5,
        mood: String = "Nötr",
        isFavorite: Bool = false,
        followUps: [DreamFollowUp] = []
    ) {
        self.id = id
        self.createdAt = createdAt
        self.title = title
        self.source = source
        self.dreamText = dreamText
        self.interpretation = interpretation
        self.previewSummary = previewSummary
        self.previewImageBase64 = previewImageBase64
        self.symbols = symbols
        self.clarity = clarity
        self.mood = mood
        self.isFavorite = isFavorite
        self.followUps = followUps
    }

    var displayTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Adsiz Ruya" : trimmed
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case createdAt
        case title
        case source
        case dreamText
        case interpretation
        case previewSummary
        case previewImageBase64
        case symbols
        case clarity
        case mood
        case isFavorite
        case followUps
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? "Adsiz Ruya"
        source = try container.decodeIfPresent(DreamInputSource.self, forKey: .source) ?? .typed
        dreamText = try container.decodeIfPresent(String.self, forKey: .dreamText) ?? ""
        interpretation = try container.decodeIfPresent(String.self, forKey: .interpretation) ?? ""
        previewSummary = try container.decodeIfPresent(String.self, forKey: .previewSummary) ?? ""
        previewImageBase64 = try container.decodeIfPresent(String.self, forKey: .previewImageBase64)
        symbols = try container.decodeIfPresent([String].self, forKey: .symbols) ?? []
        clarity = try container.decodeIfPresent(Double.self, forKey: .clarity) ?? 0.5
        mood = try container.decodeIfPresent(String.self, forKey: .mood) ?? "Nötr"
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        followUps = try container.decodeIfPresent([DreamFollowUp].self, forKey: .followUps) ?? []
    }
}

struct WalletState: Codable {
    var freeInterpretationsUsed: Int
    var credits: Int
}

enum UsageCharge {
    case free
    case credit(Int)
}
