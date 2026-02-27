import Foundation

struct OpenAIService {
    private let client: BackendAIClient

    init(client: BackendAIClient = .live()) {
        self.client = client
    }

    func interpretDream(text: String) async throws -> String {
        let userInput = """
        Kullanicinin anlattigi ruya:
        \(text)

        Lutfen Jung yaklasimina gore cok detayli bir analiz yap.
        """

        return try await createTextResponse(
            systemPrompt: Self.jungDreamSystemPrompt,
            userInput: userInput,
            maxOutputTokens: 900
        )
    }

    func rebuildDreamFromFragments(fragments: String, mood: String) async throws -> String {
        let userInput = """
        Kullanici ruyasini tam hatirlamiyor, sadece parcali detaylar paylasti:
        \(fragments)

        Secilen duygu tonu:
        \(mood)
        """

        return try await createTextResponse(
            systemPrompt: Self.jungDreamRebuilderSystemPrompt,
            userInput: userInput,
            maxOutputTokens: 420
        )
    }

    func createDreamPreview(dreamText: String, interpretation: String) async throws -> String {
        let userInput = """
        Ruya metni:
        \(dreamText)

        Ayrintili Jung yorumu:
        \(interpretation)
        """

        return try await createTextResponse(
            systemPrompt: Self.jungPreviewSystemPrompt,
            userInput: userInput,
            maxOutputTokens: 160
        )
    }

    func extractDreamKeywords(dreamText: String, interpretation: String) async throws -> [String] {
        let userInput = """
        Ruya metni:
        \(dreamText)

        Ayrintili Jung yorumu:
        \(interpretation)
        """

        let raw = try await createTextResponse(
            systemPrompt: Self.jungKeywordSystemPrompt,
            userInput: userInput,
            maxOutputTokens: 80
        )

        let keywords = raw
            .replacingOccurrences(of: "\n", with: ",")
            .split(separator: ",")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var unique: [String] = []
        for item in keywords where !unique.contains(item) {
            unique.append(item)
            if unique.count == 4 { break }
        }
        return unique
    }

    func generateDreamTitle(dreamText: String, interpretation: String) async throws -> String {
        let userInput = """
        Ruya metni:
        \(dreamText)

        Ayrintili Jung yorumu:
        \(interpretation)
        """

        let raw = try await createTextResponse(
            systemPrompt: Self.jungTitleSystemPrompt,
            userInput: userInput,
            maxOutputTokens: 40
        )
        return raw.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func answerFollowUp(
        dreamText: String,
        interpretation: String,
        followUps: [DreamFollowUp],
        question: String
    ) async throws -> String {
        let followUpContext: String
        if followUps.isEmpty {
            followUpContext = "Daha once soru sorulmadi."
        } else {
            followUpContext = followUps.enumerated().map { index, item in
                "\(index + 1). Soru: \(item.question)\nCevap: \(item.answer)"
            }.joined(separator: "\n\n")
        }

        let userInput = """
        Orijinal ruya:
        \(dreamText)

        Ilk Jung yorumu:
        \(interpretation)

        Onceki soru-cevaplar:
        \(followUpContext)

        Yeni soru:
        \(question)
        """

        return try await createTextResponse(
            systemPrompt: Self.jungFollowUpSystemPrompt,
            userInput: userInput,
            maxOutputTokens: 700
        )
    }

    func transcribeAudio(fileURL: URL) async throws -> String {
        let decoded = try await client.transcribeAudio(fileURL: fileURL)
        let text = decoded.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty {
            throw OpenAIServiceError.invalidResponse("Transkript bos dondu.")
        }
        return text
    }

    private func createTextResponse(
        systemPrompt: String,
        userInput: String,
        maxOutputTokens: Int
    ) async throws -> String {
        let body = ResponseRequest(
            model: "gpt-4.1-mini",
            input: [
                .init(role: "system", content: [.init(type: "input_text", text: systemPrompt)]),
                .init(role: "user", content: [.init(type: "input_text", text: userInput)])
            ],
            maxOutputTokens: maxOutputTokens
        )

        let decoded = try await client.interpret(body)

        if let outputText = decoded.outputText?.trimmingCharacters(in: .whitespacesAndNewlines), !outputText.isEmpty {
            return outputText
        }

        let fallback = decoded.output?
            .flatMap { $0.content ?? [] }
            .compactMap { $0.text }
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !fallback.isEmpty {
            return fallback
        }

        throw OpenAIServiceError.invalidResponse("Model cevabindan metin cikartilamadi.")
    }
}

struct BackendAIClient {
    private let session: URLSession
    private let baseURL: URL
    private let debugAuthToken: String?

    init(
        baseURL: URL = BackendConfiguration.resolveBaseURL(),
        session: URLSession = .shared,
        debugAuthToken: String? = BackendConfiguration.resolveDebugAuthToken()
    ) {
        self.baseURL = baseURL
        self.session = session
        self.debugAuthToken = debugAuthToken
    }

    static func live() -> BackendAIClient {
        BackendAIClient()
    }

    fileprivate func interpret(_ requestBody: ResponseRequest) async throws -> ResponseResult {
        try BackendConfiguration.validateRuntimeBaseURL(baseURL)
        var request = makeJSONRequest(path: "v1/dream/interpret")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data)
        return try JSONDecoder().decode(ResponseResult.self, from: data)
    }

    func transcribeAudio(fileURL: URL) async throws -> BackendTranscriptionResult {
        try BackendConfiguration.validateRuntimeBaseURL(baseURL)
        let fileData = try Data(contentsOf: fileURL)
        let payload = BackendTranscriptionRequest(
            model: "gpt-4o-mini-transcribe",
            language: "tr",
            filename: fileURL.lastPathComponent,
            mimeType: Self.mimeType(for: fileURL),
            audioBase64: fileData.base64EncodedString()
        )

        var request = makeJSONRequest(path: "v1/dream/transcribe")
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data)
        return try JSONDecoder().decode(BackendTranscriptionResult.self, from: data)
    }

    private func makeJSONRequest(path: String) -> URLRequest {
        let normalizedPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        let url = baseURL.appendingPathComponent(normalizedPath)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
#if DEBUG
        if let token = debugAuthToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
#endif
        return request
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else {
            throw OpenAIServiceError.invalidResponse("HTTP yaniti alinamadi.")
        }
        guard (200...299).contains(http.statusCode) else {
            if let apiError = try? JSONDecoder().decode(APIErrorEnvelope.self, from: data) {
                throw OpenAIServiceError.apiError(apiError.error.message)
            }
            throw OpenAIServiceError.apiError("HTTP \(http.statusCode) hatasi.")
        }
    }

    private static func mimeType(for fileURL: URL) -> String {
        switch fileURL.pathExtension.lowercased() {
        case "m4a":
            return "audio/m4a"
        case "mp3":
            return "audio/mpeg"
        case "wav":
            return "audio/wav"
        default:
            return "application/octet-stream"
        }
    }
}

private enum BackendConfiguration {
    private static let fallbackBaseURL = URL(string: "https://backend.example.com")!
    private static let placeholderHost = "backend.example.com"

    static func resolveBaseURL() -> URL {
        let raw = ((Bundle.main.object(forInfoDictionaryKey: "BACKEND_BASE_URL") as? String) ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if
            let url = URL(string: raw),
            let scheme = url.scheme?.lowercased(),
            ["http", "https"].contains(scheme),
            !raw.isEmpty
        {
            return url
        }
        return fallbackBaseURL
    }

    static func validateRuntimeBaseURL(_ baseURL: URL) throws {
#if DEBUG
        _ = baseURL
#else
        let host = (baseURL.host ?? "").lowercased()
        if host.isEmpty || host == placeholderHost {
            throw OpenAIServiceError.backendBaseURLMissing
        }
#endif
    }

    static func resolveDebugAuthToken() -> String? {
#if DEBUG
        let token = (ProcessInfo.processInfo.environment["BACKEND_AUTH_TOKEN"] ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return token.isEmpty ? nil : token
#else
        return nil
#endif
    }
}

private extension OpenAIService {
    static let jungDreamSystemPrompt = """
    Sen Jung odakli bir ruya analistisin.
    Ciktin Turkce olacak.
    Kullaniciya kesin teshis, kehanet, korkutucu mutlak yargi verme.
    Yorumun net ama detayli olsun.
    Asagidaki basliklari sirayla kullan:
    1) Ozet tema
    2) Semboller ve olasi Jung arketipleri
    3) Golge, anima/animus ve persona acisindan yorum
    4) Telafi (compensation) ve bireylesme sureci acisindan yorum
    5) Duygusal ton ve bilincli hayata olasi yansima
    6) Uygulanabilir 3 icgorulu soru veya pratik adim
    Kullaniciyi yargilama.
    """

    static let jungFollowUpSystemPrompt = """
    Sen Jung odakli bir ruya analistisin.
    Ciktin Turkce olacak.
    Kullanici bir takip sorusu soruyor.
    Cevabin onceki yoruma sadik, detayli ve soru odakli olsun.
    Gerekirse sembol, arketip, golge, anima/animus, telafi ve bireylesme baglamlarini kullan.
    Kisa kesme; ama gereksiz tekrar yapma.
    En sonda 1 kisa dusunme sorusu ekle.
    """

    static let jungPreviewSystemPrompt = """
    Sen ruyayi kisa ve etkili anlatan bir Jung analistisin.
    Turkce yaz.
    En fazla 2 cumle yaz.
    Ilk cumle baslik gibi olsun.
    Ikinci cumle sembolleri kisa aciklasin.
    Cevapta maddeleme ve numara kullanma.
    """

    static let jungKeywordSystemPrompt = """
    Ruya ve yoruma gore en kritik 3 veya 4 anahtar kelime ver.
    Sadece virgul ile ayrilmis kelimeler yaz.
    Ek aciklama, cumle, numara, tire kullanma.
    """

    static let jungTitleSystemPrompt = """
    Ruya metni ve Jung yorumuna gore yaratıcı, kisa bir baslik üret.
    Cikti Turkce olsun.
    En fazla 4 kelime kullan.
    Tırnak, noktalama, maddeleme, açıklama ekleme.
    Sadece baslik don.
    """

    static let jungDreamRebuilderSystemPrompt = """
    Sen ruyayi yeniden kuran bir Jung odakli yardimci asistansin.
    Cikti Turkce olacak.
    Kullanici sadece parcali anahtar kelimeler verir; sen bunlardan anlamli, akici ve dogal bir ruya anlatimi olustur.
    Kurallar:
    - 1 kisa baslik satiri + 1-2 paragraf ruya anlatimi yaz.
    - Asiri korkutucu, dehset verici veya travmatik ayrintilar ekleme.
    - Verilen ipuclarina sadik kal, ama tutarli bir akis kur.
    - Yorum yapma, sadece ruyanin anlatimini yaz.
    - Ciktinin sonuna su satiri ekleme: "Yorum:" veya benzeri.
    """
}

fileprivate struct ResponseRequest: Encodable {
    let model: String
    let input: [ResponseInput]
    let maxOutputTokens: Int

    enum CodingKeys: String, CodingKey {
        case model
        case input
        case maxOutputTokens = "max_output_tokens"
    }
}

fileprivate struct ResponseInput: Encodable {
    let role: String
    let content: [ResponseInputContent]
}

fileprivate struct ResponseInputContent: Encodable {
    let type: String
    let text: String
}

fileprivate struct ResponseResult: Decodable {
    let outputText: String?
    let output: [ResponseOutput]?

    enum CodingKeys: String, CodingKey {
        case outputText = "output_text"
        case output
    }
}

fileprivate struct ResponseOutput: Decodable {
    let content: [ResponseOutputContent]?
}

fileprivate struct ResponseOutputContent: Decodable {
    let text: String?
}

private struct BackendTranscriptionRequest: Encodable {
    let model: String
    let language: String
    let filename: String
    let mimeType: String
    let audioBase64: String
}

struct BackendTranscriptionResult: Decodable {
    let text: String
}

private struct APIErrorEnvelope: Decodable {
    let error: APIError
}

private struct APIError: Decodable {
    let message: String
}

enum OpenAIServiceError: LocalizedError {
    case apiError(String)
    case invalidResponse(String)
    case backendBaseURLMissing

    var errorDescription: String? {
        switch self {
        case .apiError(let message):
            return "AI servis hatasi: \(message)"
        case .invalidResponse(let message):
            return "Gecersiz API cevabi: \(message)"
        case .backendBaseURLMissing:
            return String(localized: "error.backend.base_url_missing")
        }
    }
}
