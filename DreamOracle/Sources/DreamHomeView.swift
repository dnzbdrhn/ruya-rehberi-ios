import SwiftUI

struct DreamHomeView: View {
    @ObservedObject var viewModel: DreamInterpreterViewModel
    let onOpenComposer: () -> Void
    let onOpenVoiceComposer: () -> Void
    let onOpenInterpretation: (UUID) -> Void
    @Environment(\.usesSharedTabPanoramaBackground) private var usesSharedTabPanoramaBackground

    var body: some View {
        ZStack {
            if !usesSharedTabPanoramaBackground {
                DreamBackground()
            }
            ScrollView(showsIndicators: false) {
                VStack(spacing: DreamLayout.sectionSpacing) {
                    header
                    shareBar
                    historyPanel
                    dailyAnalysisCard
                    messages
                }
                .padding(.horizontal, DreamLayout.screenHorizontal)
                .padding(.top, DreamLayout.screenTop)
                .padding(.bottom, DreamLayout.screenBottom)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        HStack(alignment: .center) {
            Text("Rüya Rehberi")
                .font(DreamTheme.heading(39))
                .foregroundStyle(DreamTheme.textPrimary)
            Spacer()
            Button {
                // Settings placeholder.
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(DreamTheme.goldStart)
                    .padding(11)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.12))
                    )
                    .overlay(
                        Circle()
                            .stroke(DreamTheme.goldStart.opacity(0.65), lineWidth: 1)
                    )
                    .clipShape(Circle())
            }
        }
    }

    private var shareBar: some View {
        HStack(spacing: 12) {
            Button {
                onOpenVoiceComposer()
            } label: {
                Image(systemName: "mic.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(DreamTheme.textDark)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.45))
                    .clipShape(Circle())
            }

            Button {
                onOpenComposer()
            } label: {
                HStack(spacing: 10) {
                    Text("Rüyanızı Paylaşın")
                        .font(DreamTheme.medium(19.5))
                        .foregroundStyle(DreamTheme.textDark)
                        .lineLimit(1)

                    Spacer(minLength: 8)

                    Image(systemName: "keyboard")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(DreamTheme.textDark)
                        .frame(width: 38, height: 38)
                        .background(Color.white.opacity(0.42))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 13)
        .background(
            LinearGradient(
                colors: [DreamTheme.goldStart, DreamTheme.goldEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 21, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 21, style: .continuous)
                .stroke(Color.white.opacity(0.25), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.22), radius: 10, y: 6)
    }

    private var historyPanel: some View {
        VStack(spacing: 0) {
            if viewModel.dreamRecords.isEmpty {
                placeholderRow(title: "Uçan Fil", date: "18.05.2024", icon: "tortoise.fill")
                divider
                placeholderRow(title: "Rüyan Böğedi", date: "18.04.2024", icon: "moon.fill")
                divider
                placeholderRow(title: "Rüyan Rasun Talci", date: "16.04.2024", icon: "cloud.fill")
            } else {
                ForEach(Array(viewModel.dreamRecords.prefix(3).enumerated()), id: \.element.id) { index, record in
                    Button {
                        onOpenInterpretation(record.id)
                    } label: {
                        historyRow(record: record)
                    }
                    .buttonStyle(.plain)

                    if index < min(2, viewModel.dreamRecords.count - 1) {
                        divider
                    }
                }
            }
        }
        .dreamCard(light: true, cornerRadius: 24)
    }

    private var divider: some View {
        Divider().background(Color.black.opacity(0.09))
    }

    private func historyRow(record: DreamRecord) -> some View {
        HStack(spacing: 12) {
            iconContainer(symbol: record.symbols.first, source: record.source)
            VStack(alignment: .leading, spacing: 3) {
                Text(record.displayTitle)
                    .font(DreamTheme.medium(20))
                    .foregroundStyle(DreamTheme.textDark)
                    .lineLimit(1)
                Text(Self.dayFormatter.string(from: record.createdAt))
                    .font(DreamTheme.body(14.5))
                    .foregroundStyle(Color.black.opacity(0.47))
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.black.opacity(0.32))
        }
        .padding(.vertical, 12)
    }

    private func placeholderRow(title: String, date: String, icon: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [DreamTheme.skyTop.opacity(0.96), DreamTheme.skyBottom.opacity(0.96)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Image(systemName: icon)
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.95))
            }
            .frame(width: 54, height: 54)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(DreamTheme.medium(20))
                    .foregroundStyle(DreamTheme.textDark)
                    .lineLimit(1)
                Text(date)
                    .font(DreamTheme.body(14.5))
                    .foregroundStyle(Color.black.opacity(0.47))
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.black.opacity(0.32))
        }
        .padding(.vertical, 12)
    }

    private func iconContainer(symbol: String?, source: DreamInputSource) -> some View {
        let iconName: String
        if source == .voice {
            iconName = "waveform.circle.fill"
        } else if let symbol, !symbol.isEmpty {
            iconName = iconNameForSymbol(symbol)
        } else {
            iconName = "moon.stars.fill"
        }

        return ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [DreamTheme.skyTop.opacity(0.96), DreamTheme.skyBottom.opacity(0.96)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Image(systemName: iconName)
                .font(.system(size: 21, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.95))
        }
        .frame(width: 54, height: 54)
    }

    private func iconNameForSymbol(_ symbol: String) -> String {
        let lower = symbol.lowercased()
        if lower.contains("anahtar") { return "key.fill" }
        if lower.contains("balik") { return "fish.fill" }
        if lower.contains("deniz") { return "water.waves" }
        if lower.contains("ayakkabi") { return "shoe.2.fill" }
        if lower.contains("kus") || lower.contains("uc") { return "bird.fill" }
        if lower.contains("fil") { return "tortoise.fill" }
        return "sparkles"
    }

    private var dailyAnalysisCard: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Günlük Analiz")
                    .font(DreamTheme.medium(20.5))
                    .foregroundStyle(Color.white)

                Text(analysisPreview)
                    .font(DreamTheme.body(14.5))
                    .foregroundStyle(Color.white.opacity(0.88))
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.11))
                    .frame(width: 82, height: 82)
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(DreamTheme.goldStart)
            }
            .padding(.bottom, 4)
        }
        .padding(.vertical, 4)
        .dreamCard(light: false, cornerRadius: 24)
    }

    private var analysisPreview: String {
        if let latest = viewModel.selectedRecord?.interpretation, !latest.isEmpty {
            return latest
        }
        if !viewModel.interpretation.isEmpty {
            return viewModel.interpretation
        }
        return "Özgürlük arayışı, içsel denge ve sembolik bir yolculuk teması dikkat çekiyor."
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

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter
    }()
}
