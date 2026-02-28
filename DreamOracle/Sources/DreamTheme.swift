import SwiftUI

enum DreamTheme {
    static let skyTop = Color(red: 0.10, green: 0.15, blue: 0.37)
    static let skyMiddle = Color(red: 0.20, green: 0.22, blue: 0.50)
    static let skyBottom = Color(red: 0.35, green: 0.26, blue: 0.49)

    static let cardDark = Color(red: 0.19, green: 0.21, blue: 0.42).opacity(0.90)
    static let cardMid = Color(red: 0.28, green: 0.30, blue: 0.52).opacity(0.82)
    static let cardLight = Color.white.opacity(0.90)

    static let goldStart = Color(red: 0.96, green: 0.84, blue: 0.58)
    static let goldEnd = Color(red: 0.83, green: 0.68, blue: 0.40)

    static let textPrimary = Color.white
    static let textMuted = Color.white.opacity(0.84)
    static let textDark = Color(red: 0.15, green: 0.16, blue: 0.25)

    static func heading(_ size: CGFloat) -> Font {
        .custom("AvenirNext-Bold", size: size)
    }

    static func body(_ size: CGFloat) -> Font {
        .custom("AvenirNext-Regular", size: size)
    }

    static func medium(_ size: CGFloat) -> Font {
        .custom("AvenirNext-DemiBold", size: size)
    }
}

enum DreamLayout {
    static let screenHorizontal: CGFloat = 18
    static let screenTop: CGFloat = 14
    static let sectionSpacing: CGFloat = 14
    static let screenBottom: CGFloat = 30
}

struct DreamBackground: View {
    var body: some View {
        MysticalBackgroundView(
            prefersAsset: true,
            themeStyle: .night,
            emphasizedReadableZone: .middle
        )
    }
}

struct CloudShapes: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.height * 0.72))
        path.addCurve(
            to: CGPoint(x: rect.width * 0.2, y: rect.height * 0.55),
            control1: CGPoint(x: rect.width * 0.05, y: rect.height * 0.55),
            control2: CGPoint(x: rect.width * 0.12, y: rect.height * 0.45)
        )
        path.addCurve(
            to: CGPoint(x: rect.width * 0.42, y: rect.height * 0.57),
            control1: CGPoint(x: rect.width * 0.24, y: rect.height * 0.42),
            control2: CGPoint(x: rect.width * 0.35, y: rect.height * 0.43)
        )
        path.addCurve(
            to: CGPoint(x: rect.width * 0.6, y: rect.height * 0.48),
            control1: CGPoint(x: rect.width * 0.46, y: rect.height * 0.41),
            control2: CGPoint(x: rect.width * 0.55, y: rect.height * 0.40)
        )
        path.addCurve(
            to: CGPoint(x: rect.width * 0.83, y: rect.height * 0.58),
            control1: CGPoint(x: rect.width * 0.67, y: rect.height * 0.36),
            control2: CGPoint(x: rect.width * 0.77, y: rect.height * 0.45)
        )
        path.addCurve(
            to: CGPoint(x: rect.width, y: rect.height * 0.72),
            control1: CGPoint(x: rect.width * 0.90, y: rect.height * 0.65),
            control2: CGPoint(x: rect.width * 0.97, y: rect.height * 0.67)
        )
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        return path
    }
}

struct DreamCardModifier: ViewModifier {
    var light: Bool = false
    var cornerRadius: CGFloat = 22

    func body(content: Content) -> some View {
        content
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(light ? DreamTheme.cardLight : DreamTheme.cardDark)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(Color.white.opacity(light ? 0.20 : 0.18), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.22), radius: 14, y: 6)
    }
}

struct DreamGoldButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(DreamTheme.medium(17))
            .foregroundStyle(DreamTheme.textDark)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [DreamTheme.goldStart, DreamTheme.goldEnd],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.24), lineWidth: 0.8)
            )
    }
}

extension View {
    func dreamCard(light: Bool = false, cornerRadius: CGFloat = 22) -> some View {
        modifier(DreamCardModifier(light: light, cornerRadius: cornerRadius))
    }

    func dreamGoldButton() -> some View {
        modifier(DreamGoldButtonModifier())
    }
}

private struct UsesSharedTabPanoramaBackgroundKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var usesSharedTabPanoramaBackground: Bool {
        get { self[UsesSharedTabPanoramaBackgroundKey.self] }
        set { self[UsesSharedTabPanoramaBackgroundKey.self] = newValue }
    }
}
