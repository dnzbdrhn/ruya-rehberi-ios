import SwiftUI

struct LockedPreviewView: View {
    let text: String
    let source: PaywallSource

    @EnvironmentObject private var paywallPresenter: PaywallPresenter
    @State private var didScheduleAutoPaywall = false

    private var visibleText: String {
        text
            .split(separator: "\n")
            .prefix(2)
            .map(String.init)
            .joined(separator: "\n")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "locked_preview.title"))
                .font(DreamTheme.medium(18))
                .foregroundStyle(Color.white)

            Text(visibleText)
                .font(DreamTheme.body(15))
                .foregroundStyle(Color.white.opacity(0.92))
                .lineSpacing(2)
                .lineLimit(4)
                .multilineTextAlignment(.leading)

            Text(text)
                .font(DreamTheme.body(14))
                .foregroundStyle(Color.white.opacity(0.9))
                .lineSpacing(2)
                .lineLimit(5)
                .blur(radius: 6)
                .overlay(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.white.opacity(0.18),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Text(String(localized: "locked_preview.unlock"))
                .font(DreamTheme.medium(14))
                .foregroundStyle(DreamTheme.goldStart)
                .padding(.top, 2)
        }
        .dreamCard(light: false, cornerRadius: 20)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [DreamTheme.goldStart.opacity(0.7), Color.white.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.2
                )
        )
        .shadow(color: DreamTheme.goldStart.opacity(0.18), radius: 16, y: 8)
        .onAppear {
            guard !didScheduleAutoPaywall else { return }
            didScheduleAutoPaywall = true

            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(800))
                guard !paywallPresenter.isShowing else { return }
                paywallPresenter.present(for: source)
            }
        }
    }
}

