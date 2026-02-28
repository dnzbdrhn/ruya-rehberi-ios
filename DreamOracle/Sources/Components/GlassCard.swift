import SwiftUI

struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = DesignTokens.Glass.cardCorner
    var padding: CGFloat = DesignTokens.Spacing.md
    var style: AppThemeStyle = .night
    @ViewBuilder var content: () -> Content

    var body: some View {
        GlassSurface(style: .card, themeStyle: style, cornerRadius: cornerRadius) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                content()
            }
            .padding(padding)
        }
    }
}

#if DEBUG
struct GlassCard_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            MysticalBackgroundView()
            GlassCard {
                Text(String(localized: "design.preview.sample.body"))
                    .font(DesignTokens.Typography.body(16))
                    .foregroundStyle(Color.white)
            }
            .padding()
        }
    }
}
#endif
