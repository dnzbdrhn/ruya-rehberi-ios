import SwiftUI
import UIKit

struct DreamInterpretationView: View {
    @ObservedObject var viewModel: DreamInterpreterViewModel
    let showsBackButton: Bool
    let onBack: (() -> Void)?

    @State private var showFullAnalysis = false
    @State private var showQuestionInput = false
    @State private var questionText = ""
    @FocusState private var isQuestionFocused: Bool

    init(
        viewModel: DreamInterpreterViewModel,
        showsBackButton: Bool = true,
        onBack: (() -> Void)?
    ) {
        self.viewModel = viewModel
        self.showsBackButton = showsBackButton
        self.onBack = onBack
    }

    var body: some View {
        ZStack {
            DreamBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    if let record = viewModel.selectedRecord {
                        titleSection(record: record)
                        heroCard(record: record)
                        previewCard(record: record)
                        keywordsCard(record: record)
                        dreamJournalCard(record: record)
                        expandButton
                        if showFullAnalysis {
                            fullInterpretationCard(record: record)
                            followUpBlock(record: record)
                        }
                        messages
                    } else {
                        emptyState
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, 30)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: viewModel.selectedRecordID) { _, _ in
            resetExpansionState()
        }
    }

    private func titleSection(record: DreamRecord) -> some View {
        VStack(spacing: 10) {
            HStack {
                if showsBackButton {
                    Button {
                        onBack?()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(Color.white.opacity(0.95))
                            .font(.system(size: 21, weight: .semibold))
                    }
                } else {
                    Color.clear.frame(width: 21, height: 21)
                }
                Spacer()
            }
            .frame(height: 24)

            Text(String(localized: "interpretation.title_prefix"))
                .font(DreamTheme.medium(22))
                .foregroundStyle(Color.white.opacity(0.92))

            Text(record.displayTitle)
                .font(DreamTheme.heading(30))
                .foregroundStyle(Color.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.76)
                .allowsTightening(true)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, 12)
        }
        .padding(.bottom, 18)
    }

    private func heroCard(record: DreamRecord) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.08), DreamTheme.cardMid.opacity(0.28)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            if let image = previewImage(for: record) {
                GeometryReader { proxy in
                    Image(uiImage: image)
                        .resizable()
                        .interpolation(.high)
                        .antialiased(true)
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                }
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .padding(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.11), lineWidth: 0.8)
                        .padding(8)
                )
            } else {
                CloudShapes()
                    .fill(Color.white.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .padding(8)

                VStack(spacing: 6) {
                    Image(systemName: "bird.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(Color.white.opacity(0.68))
                        .offset(x: 16, y: 22)

                    Image(systemName: "tortoise.fill")
                        .font(.system(size: 88))
                        .foregroundStyle(Color.white.opacity(0.95))

                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(DreamTheme.goldStart)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .background(
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [DreamTheme.skyTop.opacity(0.38), DreamTheme.skyBottom.opacity(0.34)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            DreamTheme.goldStart.opacity(0.34),
                            Color.white.opacity(0.16),
                            DreamTheme.goldEnd.opacity(0.28)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.9
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
        .shadow(color: .black.opacity(0.24), radius: 16, y: 8)
        .padding(.top, 3)
        .padding(.bottom, 8)
    }

    private func previewCard(record: DreamRecord) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(primaryPreviewLine(from: record.previewSummary))
                .font(DreamTheme.medium(24))
                .foregroundStyle(Color.white)

            Text(secondaryPreviewLine(from: record.previewSummary))
                .font(DreamTheme.body(16))
                .foregroundStyle(Color.white.opacity(0.90))
                .lineSpacing(2)
        }
        .dreamCard(light: false, cornerRadius: 22)
    }

    private func keywordsCard(record: DreamRecord) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "interpretation.keywords"))
                .font(DreamTheme.medium(20))
                .foregroundStyle(Color.white)
            FlexibleTagWrap(
                tags: record.symbols.isEmpty
                    ? [
                        String(localized: "interpretation.tag.elephant"),
                        String(localized: "interpretation.tag.flying"),
                        String(localized: "interpretation.tag.freedom")
                    ]
                    : record.symbols
            )
        }
        .dreamCard(light: false, cornerRadius: 20)
    }

    private func dreamJournalCard(record: DreamRecord) -> some View {
        let metrics = dreamMetrics(for: record)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                Text(String(localized: "interpretation.journal"))
                    .font(DreamTheme.medium(20))
                    .foregroundStyle(Color.white)

                Spacer()

                Text(Self.journalDateFormatter.string(from: record.createdAt))
                    .font(DreamTheme.body(13))
                    .foregroundStyle(Color.white.opacity(0.72))
            }

            HStack(spacing: 8) {
                Text(emojiForMood(record.mood))
                    .font(.system(size: 16))
                Text(record.mood.uppercased(with: .autoupdatingCurrent))
                    .font(DreamTheme.medium(13))
                    .foregroundStyle(Color.white.opacity(0.86))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.18))
            .clipShape(Capsule())

            DreamProfileBarChart(metrics: metrics)

            Text(record.dreamText)
                .font(DreamTheme.body(16))
                .foregroundStyle(Color.white.opacity(0.92))
                .lineSpacing(2.5)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .dreamCard(light: false, cornerRadius: 20)
    }

    private var expandButton: some View {
        Button(showFullAnalysis ? String(localized: "interpretation.expand.open") : String(localized: "interpretation.expand.more")) {
            withAnimation(.easeInOut(duration: 0.2)) {
                showFullAnalysis = true
            }
        }
        .dreamGoldButton()
        .disabled(showFullAnalysis)
    }

    private func fullInterpretationCard(record: DreamRecord) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "interpretation.full_title"))
                .font(DreamTheme.medium(21))
                .foregroundStyle(Color.white)
            Text(record.interpretation)
                .font(DreamTheme.body(15.5))
                .foregroundStyle(Color.white.opacity(0.9))
                .lineSpacing(2)
        }
        .dreamCard(light: false, cornerRadius: 20)
    }

    private func followUpBlock(record: DreamRecord) -> some View {
        VStack(spacing: 10) {
            if !showQuestionInput {
                Button(String(localized: "interpretation.followup.ask_button")) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showQuestionInput = true
                    }
                }
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .dreamGoldButton()
            }

            if showQuestionInput {
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "interpretation.followup.prompt"))
                        .font(DreamTheme.medium(15))
                        .foregroundStyle(Color.white.opacity(0.9))

                    TextField(String(localized: "interpretation.followup.placeholder"), text: $questionText, axis: .vertical)
                        .focused($isQuestionFocused)
                        .lineLimit(3, reservesSpace: true)
                        .font(DreamTheme.body(16))
                        .padding(10)
                        .background(Color.white.opacity(0.14))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .foregroundStyle(Color.white)

                    HStack {
                        Text(
                            String(
                                format: String(localized: "interpretation.followup.credits_format"),
                                locale: .autoupdatingCurrent,
                                viewModel.credits
                            )
                        )
                            .font(DreamTheme.body(13))
                            .foregroundStyle(Color.white.opacity(0.75))

                        Spacer()

                        Button {
                            askQuestion(recordID: record.id)
                        } label: {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .tint(DreamTheme.textDark)
                                }
                                Text(String(localized: "common.send"))
                            }
                            .dreamGoldButton()
                        }
                        .frame(maxWidth: 150)
                        .disabled(
                            viewModel.isLoading ||
                            !viewModel.canAffordFollowUpQuestion ||
                            questionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        )
                    }
                }
                .dreamCard(light: false, cornerRadius: 18)
            }

            if !record.followUps.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "interpretation.followup.recent"))
                        .font(DreamTheme.medium(15))
                        .foregroundStyle(Color.white.opacity(0.9))

                    ForEach(Array(record.followUps.suffix(2))) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(
                                String(
                                    format: String(localized: "interpretation.followup.question_prefix_format"),
                                    locale: .autoupdatingCurrent,
                                    item.question
                                )
                            )
                                .font(DreamTheme.medium(14))
                                .foregroundStyle(Color.white.opacity(0.95))
                            Text(item.answer)
                                .font(DreamTheme.body(14))
                                .foregroundStyle(Color.white.opacity(0.84))
                                .lineLimit(4)
                        }
                        .padding(10)
                        .background(Color.white.opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                    }
                }
                .dreamCard(light: false, cornerRadius: 18)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text(String(localized: "interpretation.empty.title"))
                .font(DreamTheme.heading(30))
                .foregroundStyle(Color.white)
            Text(String(localized: "interpretation.empty.subtitle"))
                .font(DreamTheme.body(17))
                .foregroundStyle(Color.white.opacity(0.86))
                .multilineTextAlignment(.center)
        }
        .dreamCard(light: false, cornerRadius: 20)
        .padding(.top, 70)
    }

    @ViewBuilder
    private var messages: some View {
        if let info = viewModel.infoMessage {
            Text(info)
                .font(DreamTheme.medium(13))
                .foregroundStyle(Color.green.opacity(0.95))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        if let error = viewModel.errorMessage {
            Text(error)
                .font(DreamTheme.medium(13))
                .foregroundStyle(Color.red.opacity(0.95))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func previewImage(for record: DreamRecord) -> UIImage? {
        guard let base64 = record.previewImageBase64 else { return nil }
        guard let data = Data(base64Encoded: base64) else { return nil }
        return GeminiImageService.normalizedUIImage(from: data) ?? UIImage(data: data)
    }

    private func resetExpansionState() {
        showFullAnalysis = false
        showQuestionInput = false
        questionText = ""
        isQuestionFocused = false
    }

    private func askQuestion(recordID: UUID) {
        let question = questionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty else { return }
        questionText = ""
        isQuestionFocused = false
        Task {
            await viewModel.askFollowUpQuestion(recordID: recordID, question: question)
        }
    }

    private func primaryPreviewLine(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return String(localized: "interpretation.preview.primary_fallback") }

        if let first = trimmed
            .split(whereSeparator: { $0 == "\n" || $0 == "." })
            .map(String.init)
            .first(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
        {
            return first.trimmingCharacters(in: .whitespacesAndNewlines) + "."
        }

        return trimmed
    }

    private func secondaryPreviewLine(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return String(localized: "interpretation.preview.secondary_fallback")
        }

        let first = primaryPreviewLine(from: trimmed)
        let cleaned = trimmed.replacingOccurrences(of: first, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.isEmpty {
            return String(localized: "interpretation.preview.secondary_empty_fallback")
        }
        return cleaned
    }

    private func emojiForMood(_ mood: String) -> String {
        let lower = mood.lowercased()
        if lower.contains("huzurlu") { return "😌" }
        if lower.contains("harika") { return "😍" }
        if lower.contains("kafası karışık") || lower.contains("kafasi karisik") { return "🤔" }
        if lower.contains("kaygılı") || lower.contains("kaygili") { return "😰" }
        if lower.contains("korkunç") || lower.contains("korkunc") { return "😱" }
        return "😐"
    }

    private func dreamMetrics(for record: DreamRecord) -> [DreamMetric] {
        let text = record.dreamText.lowercased()
        let mood = record.mood.lowercased()

        var scores: [(name: String, raw: Double, color: Color)] = [
            (String(localized: "interpretation.metric.scary"), 0.16 + keywordWeight(text, ["korku", "karan", "canavar", "tehdit", "öl", "panik", "kaç"]), Color(red: 0.94, green: 0.37, blue: 0.32)),
            (String(localized: "interpretation.metric.aware"), 0.14 + keywordWeight(text, ["fark", "kontrol", "bilinç", "gözlem", "düşün", "seçim", "karar"]), Color(red: 0.30, green: 0.84, blue: 0.86)),
            (String(localized: "interpretation.metric.emotional"), 0.18 + keywordWeight(text, ["üz", "mutlu", "sev", "özlem", "ağla", "öfke", "yalnız", "huzur"]), Color(red: 0.96, green: 0.26, blue: 0.64)),
            (String(localized: "interpretation.metric.nightmare"), 0.12 + keywordWeight(text, ["kabus", "uyand", "çığlık", "ter", "boğul", "sıkış", "çarpınt"]), Color(red: 0.56, green: 0.62, blue: 0.66)),
            (String(localized: "interpretation.metric.surreal"), 0.16 + keywordWeight(text, ["uç", "konuşan", "zaman", "uzay", "sihir", "şekil", "dönüş", "imkansız"]), Color(red: 0.57, green: 0.37, blue: 0.88))
        ]

        if mood.contains("korkunç") || mood.contains("korkunc") {
            scores[0].raw += 0.12
            scores[3].raw += 0.08
        } else if mood.contains("kaygılı") || mood.contains("kaygili") {
            scores[0].raw += 0.06
            scores[3].raw += 0.05
            scores[2].raw += 0.04
        } else if mood.contains("harika") {
            scores[1].raw += 0.06
            scores[2].raw += 0.07
        } else if mood.contains("huzurlu") {
            scores[1].raw += 0.06
            scores[2].raw += 0.04
        }

        let minRaw = 0.06
        let total = max(scores.reduce(0) { $0 + max($1.raw, minRaw) }, 0.001)

        let normalized = scores.map { metric -> DreamMetric in
            let value = Int(round(max(metric.raw, minRaw) / total * 100))
            return DreamMetric(title: metric.name, value: value, color: metric.color)
        }

        let sum = normalized.reduce(0) { $0 + $1.value }
        if sum == 100 { return normalized }

        var adjusted = normalized
        let delta = 100 - sum
        if let maxIndex = adjusted.indices.max(by: { adjusted[$0].value < adjusted[$1].value }) {
            adjusted[maxIndex].value += delta
        }
        return adjusted
    }

    private func keywordWeight(_ text: String, _ stems: [String]) -> Double {
        guard !text.isEmpty else { return 0 }
        var totalMatches = 0
        for stem in stems where text.contains(stem) {
            totalMatches += 1
        }
        return min(Double(totalMatches) * 0.06, 0.30)
    }

    private static let journalDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.dateFormat = "d MMMM yyyy • HH:mm"
        return formatter
    }()
}

private struct FlexibleTagWrap: View {
    let tags: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tags.prefix(6), id: \.self) { tag in
                    tagBubble(tag)
                }
            }
            .padding(.trailing, 4)
        }
    }

    private func tagBubble(_ tag: String) -> some View {
        Text(tag)
            .font(DreamTheme.body(12.5))
            .foregroundStyle(Color.white.opacity(0.92))
            .lineLimit(1)
            .truncationMode(.tail)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(Color.white.opacity(0.12))
            .clipShape(Capsule())
    }
}

private struct DreamMetric: Identifiable {
    let id = UUID()
    let title: String
    var value: Int
    let color: Color
}

private struct DreamProfileBarChart: View {
    let metrics: [DreamMetric]

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            ForEach(metrics) { metric in
                VStack(spacing: 7) {
                    ZStack(alignment: .bottom) {
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 118)

                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [metric.color.opacity(0.95), metric.color.opacity(0.45)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: max(8, CGFloat(metric.value) * 1.1))
                    }

                    Text("%\(metric.value)")
                        .font(DreamTheme.medium(13))
                        .foregroundStyle(Color.white.opacity(0.94))

                    Text(metric.title)
                        .font(DreamTheme.body(12))
                        .foregroundStyle(Color.white.opacity(0.75))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}
