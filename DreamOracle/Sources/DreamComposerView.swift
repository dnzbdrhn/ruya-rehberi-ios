import SwiftUI

struct DreamComposerView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: DreamInterpreterViewModel
    let startInVoiceMode: Bool
    let onSaved: () -> Void

    @State private var detailText = ""
    @State private var claritySun = 0.58
    @State private var clarityMoon = 0.42
    @State private var moodSliderValue = 2.0
    @State private var usedVoiceInput = false
    @State private var hasAutoStartedVoice = false
    @State private var isTranscribingVoice = false

    @State private var isRebuilderExpanded = false
    @State private var fragmentsText = ""

    @FocusState private var isDetailFocused: Bool
    @FocusState private var isFragmentsFocused: Bool

    private let moodEmojis = ["😌", "😍", "😐", "🤔", "😰", "😱"]
    private let moodTitles = ["Huzurlu", "Harika", "Nötr", "Kafası Karışık", "Kaygılı", "Korkunç"]

    init(
        viewModel: DreamInterpreterViewModel,
        startInVoiceMode: Bool = false,
        onSaved: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.startInVoiceMode = startInVoiceMode
        self.onSaved = onSaved
    }

    var body: some View {
        ZStack {
            DreamBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    topBar
                    detailField

                    if isRebuilderExpanded {
                        rebuilderPanel
                    }

                    controlPanels
                    saveButton
                    messages
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            guard startInVoiceMode, !hasAutoStartedVoice else { return }
            hasAutoStartedVoice = true
            _ = await viewModel.toggleComposerRecording()
        }
    }

    private var selectedMoodIndex: Int {
        let index = Int(moodSliderValue.rounded())
        return min(max(index, 0), moodTitles.count - 1)
    }

    private var selectedMoodTitle: String {
        moodTitles[selectedMoodIndex]
    }

    private var topBar: some View {
        HStack {
            Button {
                if viewModel.isRecording {
                    Task { _ = await viewModel.toggleComposerRecording() }
                }
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.95))
            }

            Text("Yeni Rüya")
                .font(DreamTheme.heading(35 * 0.83))
                .foregroundStyle(Color.white)
                .padding(.leading, 8)

            Spacer()
        }
    }

    private var detailField: some View {
        VStack(alignment: .leading, spacing: 7) {
            ZStack(alignment: .topLeading) {
                if detailText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("Rüyanızı anlatın...")
                        .font(DreamTheme.body(18))
                        .foregroundStyle(Color.white.opacity(0.36))
                        .padding(.top, 16)
                        .padding(.leading, 16)
                }

                TextEditor(text: $detailText)
                    .focused($isDetailFocused)
                    .font(DreamTheme.body(18))
                    .foregroundStyle(Color.white.opacity(0.96))
                    .frame(minHeight: 240)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 10)
                    .padding(.top, 8)
                    .padding(.bottom, 46)
                    .background(Color.white.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 17, style: .continuous)
                            .stroke(Color.white.opacity(0.22), lineWidth: 1)
                    )

                HStack(spacing: 10) {
                    Button {
                        isDetailFocused = false
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isRebuilderExpanded.toggle()
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(
                                    isRebuilderExpanded
                                    ? LinearGradient(
                                        colors: [DreamTheme.goldStart, DreamTheme.goldEnd],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    : LinearGradient(
                                        colors: [Color.black.opacity(0.36), Color.black.opacity(0.36)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            Image(systemName: "sparkles")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(isRebuilderExpanded ? DreamTheme.textDark : Color.white)
                        }
                        .frame(width: 38, height: 38)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.24), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)

                    Button {
                        Task { await handleVoiceButtonTapped() }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(viewModel.isRecording ? Color.red.opacity(0.84) : Color.black.opacity(0.36))
                            Image(systemName: voiceButtonIcon)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Color.white)
                        }
                        .frame(width: 38, height: 38)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.24), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isLoading || isTranscribingVoice)
                }
                .padding(.trailing, 12)
                .padding(.bottom, 12)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            }
        }
    }

    private var rebuilderPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.12))
                    Image(systemName: "wand.and.sparkles")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.92))
                }
                .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Rüya Yardımcısı")
                        .font(DreamTheme.medium(19))
                        .foregroundStyle(Color.white)
                    Text("Anahtar kelimeleri detaylı rüyalara dönüştürün")
                        .font(DreamTheme.body(14))
                        .foregroundStyle(Color.white.opacity(0.68))
                }

                Spacer()
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("ANAHTAR KELIMELER VE PARÇALAR")
                        .font(DreamTheme.medium(14))
                        .kerning(1)
                        .foregroundStyle(Color.white.opacity(0.75))

                    Spacer()

                    Text("\(max(viewModel.freeRemaining, 0)) KALDI")
                        .font(DreamTheme.medium(13))
                        .foregroundStyle(Color(red: 0.67, green: 0.46, blue: 0.97))
                        .padding(.horizontal, 11)
                        .padding(.vertical, 5)
                        .background(Color(red: 0.67, green: 0.46, blue: 0.97).opacity(0.16))
                        .clipShape(Capsule())
                }

                ZStack(alignment: .topLeading) {
                    if fragmentsText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Uçmak, okyanus, çocukluk evi, tanıdık bir ses...")
                            .font(DreamTheme.body(16))
                            .foregroundStyle(Color.white.opacity(0.36))
                            .padding(.top, 14)
                            .padding(.leading, 14)
                    }

                    TextEditor(text: $fragmentsText)
                        .focused($isFragmentsFocused)
                        .font(DreamTheme.body(16))
                        .foregroundStyle(Color.white.opacity(0.95))
                        .frame(minHeight: 120)
                        .scrollContentBackground(.hidden)
                        .padding(6)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.white.opacity(0.14), lineWidth: 1)
                        )
                }

                Button {
                    isFragmentsFocused = false
                    rebuildDreamFromFragments()
                } label: {
                    HStack(spacing: 8) {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(DreamTheme.textDark)
                        } else {
                            Image(systemName: "sparkles")
                        }
                        Text("Rüya Yardımını Uygula")
                    }
                    .dreamGoldButton()
                }
                .buttonStyle(.plain)
                .disabled(
                    viewModel.isLoading ||
                    fragmentsText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                )
            }
        }
        .dreamCard(light: false, cornerRadius: 20)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private var voiceButtonIcon: String {
        if isTranscribingVoice { return "hourglass" }
        return viewModel.isRecording ? "stop.fill" : "mic.fill"
    }

    private var controlPanels: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Rüya Netliği")
                    .font(DreamTheme.medium(16))
                    .foregroundStyle(Color.white)

                HStack {
                    Image(systemName: "sun.max.fill")
                        .foregroundStyle(DreamTheme.goldStart)
                    Slider(value: $claritySun, in: 0...1)
                        .tint(Color.white)
                }

                HStack {
                    Image(systemName: "moon.stars.fill")
                        .foregroundStyle(Color.white.opacity(0.84))
                    Slider(value: $clarityMoon, in: 0...1)
                        .tint(Color.white.opacity(0.8))
                }
            }
            .dreamCard(light: false, cornerRadius: 16)

            VStack(alignment: .leading, spacing: 10) {
                Text("Duygu Durumu")
                    .font(DreamTheme.medium(16))
                    .foregroundStyle(Color.white)

                HStack(spacing: 6) {
                    ForEach(Array(moodEmojis.enumerated()), id: \.offset) { index, emoji in
                        Text(emoji)
                            .font(.system(size: selectedMoodIndex == index ? 24 : 20))
                            .opacity(selectedMoodIndex == index ? 1 : 0.58)
                            .frame(maxWidth: .infinity)
                    }
                }

                Slider(value: $moodSliderValue, in: 0...Double(moodTitles.count - 1), step: 1)
                    .tint(Color.white)

                Text(selectedMoodTitle)
                    .font(DreamTheme.body(14))
                    .foregroundStyle(Color.white.opacity(0.9))
            }
            .dreamCard(light: false, cornerRadius: 16)
        }
    }

    private var saveButton: some View {
        Button {
            saveDream()
        } label: {
            HStack(spacing: 8) {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(DreamTheme.textDark)
                }
                Text("Kaydet")
            }
            .dreamGoldButton()
        }
        .disabled(viewModel.isLoading || detailText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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

    private func handleVoiceButtonTapped() async {
        if viewModel.isRecording {
            isTranscribingVoice = true
            defer { isTranscribingVoice = false }
            if let transcript = await viewModel.toggleComposerRecording() {
                usedVoiceInput = true
                if detailText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    detailText = transcript
                } else {
                    detailText += "\n\n" + transcript
                }
            }
        } else {
            _ = await viewModel.toggleComposerRecording()
        }
    }

    private func rebuildDreamFromFragments() {
        let trimmed = fragmentsText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        Task {
            if let rebuilt = await viewModel.rebuildDreamFromFragments(trimmed, mood: selectedMoodTitle) {
                detailText = rebuilt
                usedVoiceInput = false
                withAnimation(.easeInOut(duration: 0.2)) {
                    isRebuilderExpanded = false
                }
            }
        }
    }

    private func saveDream() {
        let detail = detailText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !detail.isEmpty else { return }

        let source: DreamInputSource = usedVoiceInput ? .voice : .typed

        Task {
            await viewModel.interpretDreamFromComposer(
                title: "",
                detailText: detail,
                symbols: [],
                clarity: (claritySun + clarityMoon) / 2,
                mood: selectedMoodTitle,
                source: source
            )

            if viewModel.errorMessage == nil {
                onSaved()
                dismiss()
            }
        }
    }
}
