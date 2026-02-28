import SwiftUI

struct GlowIconButton: View {
    let systemImage: String
    let accessibilityLabelKey: LocalizedStringKey
    var size: CGFloat = 52
    var style: AppThemeStyle = .night
    var action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let colors = Theme.colors(for: colorScheme, style: style)

        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: max(18, size * 0.36), weight: .semibold))
                .foregroundStyle(colors.textPrimary)
                .frame(width: max(size, DesignTokens.minimumTapSize), height: max(size, DesignTokens.minimumTapSize))
                .background(
                    Circle()
                        .fill(colors.surfaceElevated.opacity(0.80))
                        .overlay(
                            Circle()
                                .stroke(colors.border, lineWidth: DesignTokens.Stroke.regular)
                        )
                )
                .shadow(color: colors.glow.opacity(0.30), radius: DesignTokens.Glow.medium, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(accessibilityLabelKey))
    }
}

#if DEBUG
struct GlowIconButton_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            MysticalBackgroundView()
            HStack(spacing: 18) {
                GlowIconButton(
                    systemImage: "mic.fill",
                    accessibilityLabelKey: "design.preview.icon.mic",
                    action: {}
                )
                GlowIconButton(
                    systemImage: "sparkles",
                    accessibilityLabelKey: "design.preview.icon.sparkle",
                    action: {}
                )
                GlowIconButton(
                    systemImage: "plus",
                    accessibilityLabelKey: "design.preview.icon.plus",
                    action: {}
                )
            }
        }
    }
}
#endif
