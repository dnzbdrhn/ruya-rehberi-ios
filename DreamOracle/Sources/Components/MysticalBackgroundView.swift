import SwiftUI
import UIKit

enum MysticalScreenZone {
    case top
    case middle
    case bottom
}

struct MysticalBackgroundView: View {
    var prefersAsset = true
    var themeStyle: AppThemeStyle = .night
    var emphasizedReadableZone: MysticalScreenZone = .middle

    @Environment(\.colorScheme) private var colorScheme

    private static let stars: [CGPoint] = [
        CGPoint(x: 0.06, y: 0.08), CGPoint(x: 0.14, y: 0.15), CGPoint(x: 0.23, y: 0.07),
        CGPoint(x: 0.31, y: 0.18), CGPoint(x: 0.42, y: 0.10), CGPoint(x: 0.53, y: 0.14),
        CGPoint(x: 0.61, y: 0.05), CGPoint(x: 0.70, y: 0.12), CGPoint(x: 0.79, y: 0.18),
        CGPoint(x: 0.88, y: 0.08), CGPoint(x: 0.93, y: 0.17), CGPoint(x: 0.17, y: 0.24),
        CGPoint(x: 0.27, y: 0.30), CGPoint(x: 0.38, y: 0.26), CGPoint(x: 0.48, y: 0.22),
        CGPoint(x: 0.58, y: 0.30), CGPoint(x: 0.67, y: 0.24), CGPoint(x: 0.76, y: 0.29),
        CGPoint(x: 0.84, y: 0.23), CGPoint(x: 0.92, y: 0.28)
    ]

    var body: some View {
        GeometryReader { proxy in
            let colors = Theme.colors(for: colorScheme, style: themeStyle)

            ZStack {
                if let background = backgroundImage {
                    background
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                        .ignoresSafeArea()
                    Color.black.opacity(0.14).ignoresSafeArea()
                } else {
                    Theme.backgroundGradient(colors).ignoresSafeArea()
                }

                starField(in: proxy.size)
                readabilityLayer(colors: colors)
            }
        }
    }

    private var backgroundImage: Image? {
        guard prefersAsset else { return nil }
        let candidates = ["arkaplan_new", "arkaplan"]
        for name in candidates where UIImage(named: name) != nil {
            return Image(name)
        }
        return nil
    }

    @ViewBuilder
    private func starField(in size: CGSize) -> some View {
        ForEach(Array(Self.stars.enumerated()), id: \.offset) { index, point in
            Image(systemName: index.isMultiple(of: 3) ? "sparkles" : "circle.fill")
                .font(.system(size: index.isMultiple(of: 3) ? 7 : 3.5))
                .foregroundStyle(Color.white.opacity(index.isMultiple(of: 3) ? 0.52 : 0.38))
                .position(x: point.x * size.width, y: point.y * size.height)
                .allowsHitTesting(false)
        }
    }

    private func readabilityLayer(colors: Theme.Colors) -> some View {
        ZStack {
            LinearGradient(
                colors: [Color.black.opacity(0.34), .clear],
                startPoint: .top,
                endPoint: .center
            )

            LinearGradient(
                colors: [.clear, Color.black.opacity(0.30)],
                startPoint: .center,
                endPoint: .bottom
            )

            RadialGradient(
                colors: [Color.black.opacity(0.06), Color.black.opacity(0.24)],
                center: centerPoint(for: emphasizedReadableZone),
                startRadius: 30,
                endRadius: 640
            )

            LinearGradient(
                colors: [Color.clear, colors.backgroundBottom.opacity(0.10)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }

    private func centerPoint(for zone: MysticalScreenZone) -> UnitPoint {
        switch zone {
        case .top:
            return UnitPoint(x: 0.5, y: 0.22)
        case .middle:
            return .center
        case .bottom:
            return UnitPoint(x: 0.5, y: 0.78)
        }
    }
}

#if DEBUG
struct MysticalBackgroundView_Previews: PreviewProvider {
    static var previews: some View {
        MysticalBackgroundView()
            .ignoresSafeArea()
    }
}
#endif
