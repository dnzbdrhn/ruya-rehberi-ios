import Foundation

struct OpenAIService {
    private let session: URLSession
    private let apiKey: String

    init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
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
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/audio/transcriptions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let audioData = try Data(contentsOf: fileURL)
        var body = Data()

        body.appendField(named: "model", value: "gpt-4o-mini-transcribe", using: boundary)
        body.appendField(named: "language", value: "tr", using: boundary)
        body.appendFile(named: "file", filename: fileURL.lastPathComponent, mimeType: "audio/m4a", fileData: audioData, using: boundary)
        body.appendString("--\(boundary)--\r\n")
        request.httpBody = body

        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data)

        let decoded = try JSONDecoder().decode(TranscriptionResult.self, from: data)
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
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/responses")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let body = ResponseRequest(
            model: "gpt-4.1-mini",
            input: [
                .init(role: "system", content: [.init(type: "input_text", text: systemPrompt)]),
                .init(role: "user", content: [.init(type: "input_text", text: userInput)])
            ],
            maxOutputTokens: maxOutputTokens
        )

        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data)

        let decoded = try JSONDecoder().decode(ResponseResult.self, from: data)
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

private struct ResponseRequest: Encodable {
    let model: String
    let input: [ResponseInput]
    let maxOutputTokens: Int

    enum CodingKeys: String, CodingKey {
        case model
        case input
        case maxOutputTokens = "max_output_tokens"
    }
}

private struct ResponseInput: Encodable {
    let role: String
    let content: [ResponseInputContent]
}

private struct ResponseInputContent: Encodable {
    let type: String
    let text: String
}

private struct ResponseResult: Decodable {
    let outputText: String?
    let output: [ResponseOutput]?

    enum CodingKeys: String, CodingKey {
        case outputText = "output_text"
        case output
    }
}

private struct ResponseOutput: Decodable {
    let content: [ResponseOutputContent]?
}

private struct ResponseOutputContent: Decodable {
    let text: String?
}

private struct TranscriptionResult: Decodable {
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

    var errorDescription: String? {
        switch self {
        case .apiError(let message):
            return "OpenAI hatasi: \(message)"
        case .invalidResponse(let message):
            return "Gecersiz API cevabi: \(message)"
        }
    }
}

private extension Data {
    mutating func appendString(_ string: String) {
        append(Data(string.utf8))
    }

    mutating func appendField(named name: String, value: String, using boundary: String) {
        appendString("--\(boundary)\r\n")
        appendString("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
        appendString("\(value)\r\n")
    }

    mutating func appendFile(named name: String, filename: String, mimeType: String, fileData: Data, using boundary: String) {
        appendString("--\(boundary)\r\n")
        appendString("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n")
        appendString("Content-Type: \(mimeType)\r\n\r\n")
        append(fileData)
        appendString("\r\n")
    }
}
