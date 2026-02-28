import Foundation

enum DreamInputSource: String, Codable {
    case typed
    case voice
}

enum DreamMoodKind: String, CaseIterable {
    case peaceful
    case great
    case neutral
    case confused
    case anxious
    case scary

    var localizationKey: String {
        "mood.\(rawValue)"
    }

    var emoji: String {
        switch self {
        case .peaceful: return "😌"
        case .great: return "😍"
        case .neutral: return "😐"
        case .confused: return "🤔"
        case .anxious: return "😰"
        case .scary: return "😱"
        }
    }

    private var tokens: [String] {
        switch self {
        case .peaceful:
            return ["huzurlu", "peaceful"]
        case .great:
            return ["harika", "great"]
        case .neutral:
            return ["notr", "neutral"]
        case .confused:
            return ["kafasi karisik", "confused"]
        case .anxious:
            return ["kaygili", "anxious"]
        case .scary:
            return ["korkunc", "scary"]
        }
    }

    static func detect(from rawMood: String) -> DreamMoodKind? {
        let normalized = rawMood
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .autoupdatingCurrent)
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalized.isEmpty else { return nil }
        return allCases.first { mood in
            mood.tokens.contains(where: { normalized.contains($0) })
        }
    }
}

func localizedMoodLabel(for mood: String) -> String {
    if let detected = DreamMoodKind.detect(from: mood) {
        return String(localized: String.LocalizationValue(detected.localizationKey))
    }
    return mood
}

func moodEmoji(for mood: String) -> String {
    DreamMoodKind.detect(from: mood)?.emoji ?? DreamMoodKind.neutral.emoji
}

func defaultDreamMoodLabel() -> String {
    String(localized: "mood.neutral")
}

func untitledDreamTitle() -> String {
    String(localized: "dream.title.untitled")
}

func dreamAutoFallbackTitle() -> String {
    String(localized: "dream.title.night_echo")
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
        mood: String = defaultDreamMoodLabel(),
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
        return trimmed.isEmpty ? untitledDreamTitle() : trimmed
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
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? untitledDreamTitle()
        source = try container.decodeIfPresent(DreamInputSource.self, forKey: .source) ?? .typed
        dreamText = try container.decodeIfPresent(String.self, forKey: .dreamText) ?? ""
        interpretation = try container.decodeIfPresent(String.self, forKey: .interpretation) ?? ""
        previewSummary = try container.decodeIfPresent(String.self, forKey: .previewSummary) ?? ""
        previewImageBase64 = try container.decodeIfPresent(String.self, forKey: .previewImageBase64)
        symbols = try container.decodeIfPresent([String].self, forKey: .symbols) ?? []
        clarity = try container.decodeIfPresent(Double.self, forKey: .clarity) ?? 0.5
        mood = try container.decodeIfPresent(String.self, forKey: .mood) ?? defaultDreamMoodLabel()
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
