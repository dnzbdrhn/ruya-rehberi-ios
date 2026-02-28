import SwiftUI

struct LockedPreviewOverlay<Preview: View, CTA: View>: View {
    let titleKey: LocalizedStringKey
    var subtitleKey: LocalizedStringKey? = nil
    var cornerRadius: CGFloat = DesignTokens.Glass.overlayCorner
    var blurRadius: CGFloat = 8
    var style: AppThemeStyle = .night
    @ViewBuilder var previewContent: () -> Preview
    @ViewBuilder var callToAction: () -> CTA

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let colors = Theme.colors(for: colorScheme, style: style)

        ZStack(alignment: .bottom) {
            previewContent()
                .blur(radius: blurRadius)
                .overlay(
                    LinearGradient(
                        colors: [Color.clear, Color.black.opacity(0.42)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .allowsHitTesting(false)

            GlassSurface(style: .overlay, themeStyle: style, cornerRadius: DesignTokens.Glass.overlayCorner) {
                VStack(spacing: DesignTokens.Spacing.sm) {
                    Text(titleKey)
                        .font(DesignTokens.Typography.title(18))
                        .foregroundStyle(colors.textPrimary)
                        .multilineTextAlignment(.center)

                    if let subtitleKey {
                        Text(subtitleKey)
                            .font(DesignTokens.Typography.body(14))
                            .foregroundStyle(colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                    }

                    callToAction()
                }
                .padding(DesignTokens.Spacing.md)
            }
            .padding(DesignTokens.Spacing.md)
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(colors.border.opacity(0.75), lineWidth: DesignTokens.Stroke.hairline)
        )
    }
}

#if DEBUG
struct LockedPreviewOverlay_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            MysticalBackgroundView()
            LockedPreviewOverlay(
                titleKey: "design.preview.locked.title",
                subtitleKey: "design.preview.locked.message"
            ) {
                Text(String(localized: "design.preview.sample.body"))
                    .font(DesignTokens.Typography.body(16))
                    .foregroundStyle(Color.white)
                    .padding(24)
                    .frame(maxWidth: .infinity, minHeight: 180, alignment: .topLeading)
                    .background(Color.white.opacity(0.08))
            } callToAction: {
                PrimaryCTAButton(
                    titleKey: "design.preview.cta.primary",
                    systemImage: "sparkles",
                    action: {}
                )
            }
            .padding()
        }
    }
}
#endif
