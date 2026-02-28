import SwiftUI

struct SecondaryButton: View {
    let titleKey: LocalizedStringKey
    var systemImage: String? = nil
    var isEnabled = true
    var style: AppThemeStyle = .night
    var surfaceStyle: GlassSurfaceStyle = .pill
    var action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let colors = Theme.colors(for: colorScheme, style: style)

        Button {
            guard isEnabled else { return }
            action()
        } label: {
            GlassSurface(style: surfaceStyle, themeStyle: style) {
                HStack(spacing: DesignTokens.Spacing.xs) {
                    if let systemImage {
                        Image(systemName: systemImage)
                            .font(.system(size: 14, weight: .semibold))
                    }
                    Text(titleKey)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.9)
                }
                .font(DesignTokens.Typography.label(15))
                .foregroundStyle(colors.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(minHeight: max(DesignTokens.minimumTapSize, surfaceStyle == .chip ? 38 : 48))
                .padding(.horizontal, surfaceStyle == .chip ? DesignTokens.Spacing.sm : DesignTokens.Spacing.md)
            }
        }
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1 : 0.52)
        .disabled(!isEnabled)
    }
}

#if DEBUG
struct SecondaryButton_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            MysticalBackgroundView()
            VStack(spacing: 14) {
                SecondaryButton(
                    titleKey: "design.preview.cta.secondary",
                    systemImage: "moon.stars.fill",
                    action: {}
                )
                SecondaryButton(
                    titleKey: "design.preview.cta.secondary",
                    isEnabled: false,
                    action: {}
                )
            }
            .padding()
        }
    }
}
#endif
