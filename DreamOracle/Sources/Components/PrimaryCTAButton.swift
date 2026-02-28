import SwiftUI

struct PrimaryCTAButton: View {
    let titleKey: LocalizedStringKey
    var systemImage: String? = nil
    var isEnabled = true
    var isLoading = false
    var style: AppThemeStyle = .night
    var action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let colors = Theme.colors(for: colorScheme, style: style)

        Button {
            guard isEnabled, !isLoading else { return }
            action()
        } label: {
            HStack(spacing: DesignTokens.Spacing.xs) {
                if isLoading {
                    ProgressView()
                        .tint(Color(red: 0.15, green: 0.16, blue: 0.25))
                } else if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 15, weight: .semibold))
                }

                Text(titleKey)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.9)
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
        }
        .buttonStyle(
            PrimaryCTAButtonStyle(
                colors: colors,
                isEnabled: isEnabled && !isLoading
            )
        )
        .disabled(!isEnabled || isLoading)
    }
}

private struct PrimaryCTAButtonStyle: ButtonStyle {
    let colors: Theme.Colors
    let isEnabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignTokens.Typography.title(17))
            .foregroundStyle(Color(red: 0.15, green: 0.16, blue: 0.25))
            .frame(maxWidth: .infinity)
            .frame(minHeight: max(DesignTokens.minimumTapSize, 52))
            .background(
                Theme.goldGradient(colors)
                    .saturation(configuration.isPressed ? 0.92 : 1.0)
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.32), lineWidth: DesignTokens.Stroke.hairline)
            )
            .shadow(
                color: colors.glow.opacity(configuration.isPressed ? 0.22 : 0.38),
                radius: configuration.isPressed ? DesignTokens.Glow.soft : DesignTokens.Glow.medium,
                y: configuration.isPressed ? 2 : 6
            )
            .opacity(isEnabled ? 1 : 0.52)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(DesignTokens.Motion.quick, value: configuration.isPressed)
    }
}

#if DEBUG
struct PrimaryCTAButton_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            MysticalBackgroundView()
            VStack(spacing: 14) {
                PrimaryCTAButton(
                    titleKey: "design.preview.cta.primary",
                    systemImage: "sparkles",
                    action: {}
                )
                PrimaryCTAButton(
                    titleKey: "design.preview.cta.primary",
                    isEnabled: false,
                    action: {}
                )
                PrimaryCTAButton(
                    titleKey: "design.preview.cta.primary",
                    isLoading: true,
                    action: {}
                )
            }
            .padding()
        }
    }
}
#endif
