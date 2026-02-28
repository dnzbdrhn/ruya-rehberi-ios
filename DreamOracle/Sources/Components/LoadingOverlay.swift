import SwiftUI

struct LoadingOverlay: View {
    var isVisible: Bool
    var messageKey: LocalizedStringKey? = nil
    var style: AppThemeStyle = .night

    @Environment(\.colorScheme) private var colorScheme
    @State private var isBreathing = false

    var body: some View {
        if isVisible {
            let colors = Theme.colors(for: colorScheme, style: style)

            ZStack {
                Color.black.opacity(0.22)
                    .ignoresSafeArea()

                GlassCard(cornerRadius: DesignTokens.Radius.xl, padding: DesignTokens.Spacing.lg, style: style) {
                    VStack(spacing: DesignTokens.Spacing.md) {
                        breathingIndicator(colors: colors)

                        if let messageKey {
                            Text(messageKey)
                                .font(DesignTokens.Typography.body(15))
                                .foregroundStyle(colors.textSecondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(3)
                        }
                    }
                    .frame(minWidth: 180)
                }
                .padding(.horizontal, DesignTokens.Spacing.xl)
            }
            .transition(.opacity)
            .onAppear {
                isBreathing = true
            }
            .onDisappear {
                isBreathing = false
            }
        }
    }

    private func breathingIndicator(colors: Theme.Colors) -> some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(colors.accentViolet.opacity(0.20))
                    .frame(width: 52 + CGFloat(index * 16), height: 52 + CGFloat(index * 16))
                    .scaleEffect(isBreathing ? 1.06 : 0.92)
                    .opacity(isBreathing ? 0.25 : 0.50)
                    .animation(
                        Animation.easeInOut(duration: 1.4)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.12),
                        value: isBreathing
                    )
            }

            Image(systemName: "sparkles")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(colors.accentGold)
        }
        .frame(width: 110, height: 110)
    }
}

#if DEBUG
struct LoadingOverlay_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            MysticalBackgroundView()
            LoadingOverlay(
                isVisible: true,
                messageKey: "design.preview.loading"
            )
        }
    }
}
#endif
