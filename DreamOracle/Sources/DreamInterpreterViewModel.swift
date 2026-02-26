import Foundation

@MainActor
final class DreamInterpreterViewModel: ObservableObject {
    private enum Constants {
        static let freeInterpretationLimit = 2
        static let interpretationCreditCost = 1
        static let followUpCreditCost = 1
        static let walletKey = "wallet_state_v1"
        static let recordsKey = "dream_records_v2"
    }

    @Published var dreamText = ""
    @Published var transcriptText = ""
    @Published var interpretation = ""
    @Published var isLoading = false
    @Published var isRecording = false
    @Published var errorMessage: String?
    @Published var infoMessage: String?
    @Published private(set) var credits = 0
    @Published private(set) var freeInterpretationsUsed = 0
    @Published private(set) var dreamRecords: [DreamRecord] = []
    @Published var selectedRecordID: UUID?

    private let recorder = AudioRecorder()
    private let service: OpenAIService?
    private let imageService: GeminiImageService?
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let openAIKey = Self.resolvedOpenAIAPIKey()
        if openAIKey.isEmpty {
            service = nil
            errorMessage = "Owner API key eksik. OwnerSecrets.swift icine key girin."
        } else {
            service = OpenAIService(apiKey: openAIKey)
        }

        let geminiKey = Self.resolvedGeminiAPIKey()
        imageService = geminiKey.isEmpty ? nil : GeminiImageService(apiKey: geminiKey)

        loadPersistedState()
        if selectedRecordID == nil {
            selectedRecordID = dreamRecords.first?.id
        }
    }

    var freeRemaining: Int {
        max(0, Constants.freeInterpretationLimit - freeInterpretationsUsed)
    }

    var canAffordFollowUpQuestion: Bool {
        credits >= Constants.followUpCreditCost
    }

    var selectedRecord: DreamRecord? {
        guard let selectedRecordID else { return dreamRecords.first }
        return dreamRecords.first(where: { $0.id == selectedRecordID }) ?? dreamRecords.first
    }

    func selectRecord(_ id: UUID) {
        selectedRecordID = id
        if let selected = dreamRecords.first(where: { $0.id == id }) {
            interpretation = selected.interpretation
            dreamText = selected.dreamText
        }
    }

    func interpretTypedDream() async {
        let input = dreamText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { return }
        await interpretDreamFromComposer(
            title: autoTitle(from: input),
            detailText: input,
            symbols: fallbackSymbols(from: input),
            clarity: 0.5,
            mood: "Nötr",
            source: .typed
        )
    }

    func rebuildDreamFromFragments(_ fragments: String, mood: String) async -> String? {
        let trimmed = fragments.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Anahtar kelimeleri veya hatirladigin parcalari yaz."
            return nil
        }
        guard let service else {
            errorMessage = "OpenAI baglantisi kurulamadigi icin ruya yeniden olusturulamadi."
            return nil
        }

        errorMessage = nil
        infoMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let rebuilt = try await service.rebuildDreamFromFragments(fragments: trimmed, mood: mood)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !rebuilt.isEmpty else {
                errorMessage = "Ruyayi yeniden olustururken bos sonuc dondu."
                return nil
            }
            infoMessage = "Ruya taslagi olusturuldu. Dilersen duzenleyip kaydedebilirsin."
            return rebuilt
        } catch {
            errorMessage = Self.userFriendly(error: error)
            return nil
        }
    }

    func interpretDreamFromComposer(
        title: String,
        detailText: String,
        symbols: [String],
        clarity: Double,
        mood: String,
        source: DreamInputSource = .typed
    ) async {
        let trimmedText = detailText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            errorMessage = "Ruya anlatimi bos olamaz."
            return
        }
        guard let service else {
            errorMessage = "OpenAI baglantisi kurulamadigi icin yorum yapilamadi."
            return
        }

        let charge = nextInterpretationCharge()
        guard canAfford(charge: charge) else {
            errorMessage = "2 ucretsiz hak bitti. Devam etmek icin kredi satin alin."
            return
        }

        errorMessage = nil
        infoMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let fullInterpretation = try await service.interpretDream(text: trimmedText)

            async let previewTask = service.createDreamPreview(
                dreamText: trimmedText,
                interpretation: fullInterpretation
            )
            async let keywordTask = service.extractDreamKeywords(
                dreamText: trimmedText,
                interpretation: fullInterpretation
            )
            async let titleTask = service.generateDreamTitle(
                dreamText: trimmedText,
                interpretation: fullInterpretation
            )

            let generatedPreview = (try? await previewTask)?.trimmingCharacters(in: .whitespacesAndNewlines)
            let generatedKeywords = (try? await keywordTask) ?? []
            let generatedTitle = (try? await titleTask)?.trimmingCharacters(in: .whitespacesAndNewlines)

            let mergedKeywords = mergedSymbols(
                manual: symbols,
                generated: generatedKeywords,
                fallbackFrom: trimmedText
            )
            let previewSummary = generatedPreview.flatMap { $0.isEmpty ? nil : $0 } ?? condensedPreview(from: fullInterpretation)
            let resolvedTitle = resolvedTitle(
                manualTitle: title,
                generatedTitle: generatedTitle,
                keywords: mergedKeywords,
                dreamText: trimmedText
            )

            var previewImageBase64: String?
            var imageWarning: String?
            if let imageService {
                do {
                    let imageData = try await imageService.generateDreamArtwork(
                        title: resolvedTitle,
                        keywords: mergedKeywords,
                        mood: mood,
                        dreamText: trimmedText
                    )
                    previewImageBase64 = imageData.base64EncodedString()
                } catch {
                    let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                    imageWarning = "Gorsel uretilemedi: \(message)"
                }
            }

            interpretation = fullInterpretation
            dreamText = trimmedText

            apply(charge: charge)
            let record = saveDreamRecord(
                title: resolvedTitle,
                text: trimmedText,
                interpretation: fullInterpretation,
                previewSummary: previewSummary,
                previewImageBase64: previewImageBase64,
                source: source,
                symbols: mergedKeywords,
                clarity: clarity,
                mood: mood
            )
            selectedRecordID = record.id
            persistState()

            if let imageWarning {
                infoMessage = "\(infoMessage ?? "") \(imageWarning)".trimmingCharacters(in: .whitespaces)
            }
        } catch {
            errorMessage = Self.userFriendly(error: error)
        }
    }

    func toggleComposerRecording() async -> String? {
        if isRecording {
            return await stopRecordingAndTranscribeOnly()
        } else {
            await startRecording()
            return nil
        }
    }

    // Eski akisla uyumluluk: dogrudan sesli yorum.
    func toggleRecording() async {
        if isRecording {
            await stopRecordingAndInterpret()
        } else {
            await startRecording()
        }
    }

    func purchaseCredits(_ amount: Int) {
        guard amount > 0 else { return }
        credits += amount
        persistState()
        infoMessage = "\(amount) kredi yuklendi. Toplam kredi: \(credits)"
    }

    func record(for id: UUID) -> DreamRecord? {
        dreamRecords.first(where: { $0.id == id })
    }

    func toggleFavorite(recordID: UUID) {
        guard let index = dreamRecords.firstIndex(where: { $0.id == recordID }) else { return }
        dreamRecords[index].isFavorite.toggle()
        persistState()
    }

    func askFollowUpQuestion(recordID: UUID, question: String) async {
        let trimmedQuestion = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuestion.isEmpty else { return }
        guard credits >= Constants.followUpCreditCost else {
            errorMessage = "Soru sormak icin 1 kredi gerekli."
            return
        }
        guard let service else {
            errorMessage = "OpenAI baglantisi kurulamadigi icin soru yanitlanamadi."
            return
        }
        guard let recordSnapshot = record(for: recordID) else {
            errorMessage = "Ruya kaydi bulunamadi."
            return
        }

        errorMessage = nil
        infoMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let answer = try await service.answerFollowUp(
                dreamText: recordSnapshot.dreamText,
                interpretation: recordSnapshot.interpretation,
                followUps: recordSnapshot.followUps,
                question: trimmedQuestion
            )

            guard let index = dreamRecords.firstIndex(where: { $0.id == recordID }) else { return }
            let followUp = DreamFollowUp(question: trimmedQuestion, answer: answer)
            dreamRecords[index].followUps.append(followUp)
            credits -= Constants.followUpCreditCost
            persistState()
            infoMessage = "1 kredi dusuldu. Kalan kredi: \(credits)"
        } catch {
            errorMessage = Self.userFriendly(error: error)
        }
    }

    private func startRecording() async {
        errorMessage = nil
        infoMessage = nil

        let granted = await recorder.requestPermission()
        guard granted else {
            errorMessage = "Mikrofon izni verilmedi."
            return
        }

        do {
            try recorder.startRecording()
            isRecording = true
        } catch {
            errorMessage = Self.userFriendly(error: error)
        }
    }

    private func stopRecordingAndTranscribeOnly() async -> String? {
        isRecording = false

        guard let recordedURL = recorder.stopRecording() else {
            errorMessage = "Kaydedilen ses dosyasi bulunamadi."
            return nil
        }
        guard let service else {
            errorMessage = "OpenAI baglantisi kurulamadigi icin ses islenemedi."
            return nil
        }

        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let transcript = try await service.transcribeAudio(fileURL: recordedURL)
            transcriptText = transcript
            dreamText = transcript
            infoMessage = "Ses metne donusturuldu."
            return transcript
        } catch {
            errorMessage = Self.userFriendly(error: error)
            return nil
        }
    }

    private func stopRecordingAndInterpret() async {
        guard let transcript = await stopRecordingAndTranscribeOnly() else {
            return
        }

        await interpretDreamFromComposer(
            title: autoTitle(from: transcript),
            detailText: transcript,
            symbols: fallbackSymbols(from: transcript),
            clarity: 0.5,
            mood: "Nötr",
            source: .voice
        )
    }

    private func saveDreamRecord(
        title: String,
        text: String,
        interpretation: String,
        previewSummary: String,
        previewImageBase64: String?,
        source: DreamInputSource,
        symbols: [String],
        clarity: Double,
        mood: String
    ) -> DreamRecord {
        let record = DreamRecord(
            title: title,
            source: source,
            dreamText: text,
            interpretation: interpretation,
            previewSummary: previewSummary,
            previewImageBase64: previewImageBase64,
            symbols: Array(symbols.prefix(6)),
            clarity: min(max(clarity, 0), 1),
            mood: mood
        )
        dreamRecords.insert(record, at: 0)
        return record
    }

    private func nextInterpretationCharge() -> UsageCharge {
        if freeInterpretationsUsed < Constants.freeInterpretationLimit {
            return .free
        }
        return .credit(Constants.interpretationCreditCost)
    }

    private func canAfford(charge: UsageCharge) -> Bool {
        switch charge {
        case .free:
            return true
        case .credit(let needed):
            return credits >= needed
        }
    }

    private func apply(charge: UsageCharge) {
        switch charge {
        case .free:
            freeInterpretationsUsed += 1
            infoMessage = "Ucretsiz hak kullanildi. Kalan: \(freeRemaining)"
        case .credit(let amount):
            credits -= amount
            infoMessage = "\(amount) kredi dusuldu. Kalan kredi: \(credits)"
        }
    }

    private func loadPersistedState() {
        if
            let walletData = defaults.data(forKey: Constants.walletKey),
            let wallet = try? JSONDecoder().decode(WalletState.self, from: walletData)
        {
            freeInterpretationsUsed = wallet.freeInterpretationsUsed
            credits = wallet.credits
        }

        if
            let recordsData = defaults.data(forKey: Constants.recordsKey),
            let records = try? JSONDecoder().decode([DreamRecord].self, from: recordsData)
        {
            dreamRecords = records.sorted(by: { $0.createdAt > $1.createdAt })
        } else if
            let oldData = defaults.data(forKey: "dream_records_v1"),
            let oldRecords = try? JSONDecoder().decode([DreamRecord].self, from: oldData)
        {
            dreamRecords = oldRecords.sorted(by: { $0.createdAt > $1.createdAt })
            persistState()
        }
    }

    private func persistState() {
        let wallet = WalletState(freeInterpretationsUsed: freeInterpretationsUsed, credits: credits)
        if let walletData = try? JSONEncoder().encode(wallet) {
            defaults.set(walletData, forKey: Constants.walletKey)
        }

        if let recordsData = try? JSONEncoder().encode(dreamRecords) {
            defaults.set(recordsData, forKey: Constants.recordsKey)
        }
    }

    private static func resolvedOpenAIAPIKey() -> String {
        let bundled = ((Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String) ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if isValidOpenAIAPIKey(bundled) {
            return bundled
        }

        let hardcoded = OwnerSecrets.openAIAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if isValidOpenAIAPIKey(hardcoded) {
            return hardcoded
        }

        return ""
    }

    private static func resolvedGeminiAPIKey() -> String {
        let bundled = ((Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String) ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if isValidGeminiAPIKey(bundled) {
            return bundled
        }

        let hardcoded = OwnerSecrets.geminiAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if isValidGeminiAPIKey(hardcoded) {
            return hardcoded
        }

        return ""
    }

    private static func isValidOpenAIAPIKey(_ value: String) -> Bool {
        !value.isEmpty && !value.contains("$(") && value.hasPrefix("sk-")
    }

    private static func isValidGeminiAPIKey(_ value: String) -> Bool {
        !value.isEmpty && !value.contains("$(")
    }

    private func autoTitle(from text: String) -> String {
        let words = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: " ")
            .prefix(4)
            .map(String.init)
        if words.isEmpty { return "Gece Yankisi" }
        return words.joined(separator: " ")
    }

    private func resolvedTitle(
        manualTitle: String,
        generatedTitle: String?,
        keywords: [String],
        dreamText: String
    ) -> String {
        let manual = manualTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if !manual.isEmpty, manual.lowercased() != "adsiz ruya" {
            return manual
        }

        if let generatedTitle {
            let cleanGenerated = generatedTitle
                .replacingOccurrences(of: "\"", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !cleanGenerated.isEmpty, cleanGenerated.lowercased() != "adsiz ruya" {
                return cleanGenerated
            }
        }

        if keywords.count >= 2 {
            return "\(keywords[0]) \(keywords[1])"
        }

        let fallback = autoTitle(from: dreamText)
        if fallback.lowercased() == "adsiz ruya" {
            return "Gece Yankisi"
        }
        return fallback
    }

    private func fallbackSymbols(from text: String) -> [String] {
        let blockers = Set(["ve", "ile", "ama", "icin", "gibi", "cok", "bir", "bu", "su", "o"])
        let clean = text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty && $0.count > 3 && !blockers.contains($0) }

        var unique: [String] = []
        for word in clean where !unique.contains(word) {
            unique.append(word.capitalized)
            if unique.count == 6 { break }
        }
        return unique
    }

    private func mergedSymbols(manual: [String], generated: [String], fallbackFrom text: String) -> [String] {
        var output: [String] = []

        for item in (manual + generated) {
            let trimmed = item.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            if !output.contains(trimmed) {
                output.append(trimmed)
            }
            if output.count == 6 { break }
        }

        if output.isEmpty {
            output = fallbackSymbols(from: text)
        }

        return Array(output.prefix(6))
    }

    private func condensedPreview(from interpretation: String) -> String {
        let trimmed = interpretation.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return "Özgürlük arayışı ve potansiyel. Semboller, içsel dönüşüm ve cesaret teması taşıyor."
        }

        let lines = trimmed
            .split(separator: "\n")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if lines.count >= 2 {
            return "\(lines[0])\n\(lines[1])"
        }
        return lines.first ?? trimmed
    }

    private static func userFriendly(error: Error) -> String {
        if let localized = error as? LocalizedError, let text = localized.errorDescription {
            return text
        }
        return "Beklenmeyen bir hata olustu: \(error.localizedDescription)"
    }
}
