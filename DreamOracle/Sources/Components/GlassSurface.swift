import SwiftUI

enum GlassSurfaceStyle {
    case card
    case pill
    case chip
    case overlay
}

enum GlassIntensity: String, CaseIterable, Identifiable {
    case low
    case medium
    case high

    var id: String { rawValue }

    var multiplier: CGFloat {
        switch self {
        case .low: return 0.82
        case .medium: return 1.0
        case .high: return 1.22
        }
    }

    var localizationKey: String {
        switch self {
        case .low:
            return "design.preview.intensity.low"
        case .medium:
            return "design.preview.intensity.medium"
        case .high:
            return "design.preview.intensity.high"
        }
    }
}

private struct GlassIntensityEnvironmentKey: EnvironmentKey {
    static let defaultValue: GlassIntensity = .medium
}

extension EnvironmentValues {
    var glassIntensity: GlassIntensity {
        get { self[GlassIntensityEnvironmentKey.self] }
        set { self[GlassIntensityEnvironmentKey.self] = newValue }
    }
}

struct GlassSurface<Content: View>: View {
    let style: GlassSurfaceStyle
    var themeStyle: AppThemeStyle = .night
    var cornerRadius: CGFloat?
    @ViewBuilder var content: () -> Content

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.glassIntensity) private var intensity

    var body: some View {
        if #available(iOS 18, *) {
            // TODO: Swap this branch with true LiquidGlassSurface implementation.
            legacySurface
        } else {
            legacySurface
        }
    }

    private var legacySurface: some View {
        let colors = Theme.colors(for: colorScheme, style: themeStyle)
        let recipe = legacyRecipe(for: style, intensity: intensity)
        let radius = resolvedCornerRadius(for: style, override: cornerRadius)

        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)

        return content()
            .background(
                shape
                    .fill(recipe.material)
                    .overlay(
                        shape
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.white.opacity(recipe.frostOpacity),
                                        Color.white.opacity(recipe.frostOpacity * 0.36),
                                        .clear
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 260
                                )
                            )
                            .blendMode(.plusLighter)
                    )
                    .overlay(
                        shape
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(recipe.sheenOpacity),
                                        Color.white.opacity(recipe.sheenOpacity * 0.24),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: UnitPoint(x: 0.76, y: 0.60)
                                )
                            )
                            .blendMode(.screen)
                    )
                    .overlay(
                        GlassNoiseLayer(opacity: recipe.grainOpacity)
                            .clipShape(shape)
                    )
                    .overlay(
                        shape
                            .stroke(Color.white.opacity(recipe.borderOpacity), lineWidth: recipe.borderWidth)
                    )
            )
            .shadow(
                color: colors.accentGold.opacity(recipe.glowOpacityGold),
                radius: recipe.glowRadius,
                y: recipe.glowYOffset
            )
            .shadow(
                color: colors.accentViolet.opacity(recipe.glowOpacityViolet),
                radius: recipe.glowRadius * 0.74,
                y: recipe.glowYOffset * 0.45
            )
    }

    private func resolvedCornerRadius(for style: GlassSurfaceStyle, override: CGFloat?) -> CGFloat {
        guard let override else {
            switch style {
            case .card:
                return DesignTokens.Glass.cardCorner
            case .pill:
                return DesignTokens.Glass.pillCorner
            case .chip:
                return DesignTokens.Glass.chipCorner
            case .overlay:
                return DesignTokens.Glass.overlayCorner
            }
        }
        return override
    }

    private func legacyRecipe(for style: GlassSurfaceStyle, intensity: GlassIntensity) -> LegacyGlassRecipe {
        let m = intensity.multiplier

        switch style {
        case .card:
            return LegacyGlassRecipe(
                material: .ultraThinMaterial,
                borderWidth: DesignTokens.Glass.borderWidth,
                borderOpacity: DesignTokens.Glass.borderOpacity * m,
                sheenOpacity: DesignTokens.Glass.sheenOpacity * m,
                frostOpacity: DesignTokens.Glass.frostOpacity * m,
                grainOpacity: DesignTokens.Glass.grainOpacity * m,
                glowOpacityGold: 0.22 * m,
                glowOpacityViolet: 0.14 * m,
                glowRadius: DesignTokens.Glass.glowRadius + 4,
                glowYOffset: DesignTokens.Glass.glowYOffset
            )
        case .pill:
            return LegacyGlassRecipe(
                material: .thinMaterial,
                borderWidth: 1.35,
                borderOpacity: 0.24 * m,
                sheenOpacity: 0.19 * m,
                frostOpacity: 0.17 * m,
                grainOpacity: 0.05 * m,
                glowOpacityGold: 0.24 * m,
                glowOpacityViolet: 0.17 * m,
                glowRadius: DesignTokens.Glass.glowRadius + 8,
                glowYOffset: DesignTokens.Glass.glowYOffset + 1
            )
        case .chip:
            return LegacyGlassRecipe(
                material: .ultraThinMaterial,
                borderWidth: 1.05,
                borderOpacity: 0.20 * m,
                sheenOpacity: 0.14 * m,
                frostOpacity: 0.10 * m,
                grainOpacity: 0.04 * m,
                glowOpacityGold: 0.14 * m,
                glowOpacityViolet: 0.10 * m,
                glowRadius: DesignTokens.Glass.glowRadius - 4,
                glowYOffset: 3
            )
        case .overlay:
            return LegacyGlassRecipe(
                material: .thinMaterial,
                borderWidth: 1.25,
                borderOpacity: 0.22 * m,
                sheenOpacity: 0.17 * m,
                frostOpacity: 0.18 * m,
                grainOpacity: 0.05 * m,
                glowOpacityGold: 0.18 * m,
                glowOpacityViolet: 0.12 * m,
                glowRadius: DesignTokens.Glass.glowRadius + 2,
                glowYOffset: DesignTokens.Glass.glowYOffset
            )
        }
    }
}

private struct LegacyGlassRecipe {
    let material: Material
    let borderWidth: CGFloat
    let borderOpacity: CGFloat
    let sheenOpacity: CGFloat
    let frostOpacity: CGFloat
    let grainOpacity: CGFloat
    let glowOpacityGold: CGFloat
    let glowOpacityViolet: CGFloat
    let glowRadius: CGFloat
    let glowYOffset: CGFloat
}

private struct GlassNoiseLayer: View {
    let opacity: CGFloat

    var body: some View {
        Canvas(rendersAsynchronously: true) { context, size in
            let step: CGFloat = 9
            let columns = max(Int(size.width / step), 1)
            let rows = max(Int(size.height / step), 1)

            for row in 0...rows {
                for column in 0...columns {
                    let seed = ((row * 73) + (column * 191)) % 23
                    guard seed < 5 else { continue }

                    let x = CGFloat(column) * step + CGFloat((seed * 3) % 7)
                    let y = CGFloat(row) * step + CGFloat((seed * 5) % 7)
                    let rect = CGRect(x: x, y: y, width: 1, height: 1)
                    let tone = seed.isMultiple(of: 2) ? Color.white.opacity(0.55) : Color.black.opacity(0.45)

                    context.fill(Path(ellipseIn: rect), with: .color(tone))
                }
            }
        }
        .blendMode(.overlay)
        .opacity(opacity)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

#if DEBUG
struct GlassSurface_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            MysticalBackgroundView()
            GlassSurface(style: .card) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "design.preview.sample.body"))
                        .font(DesignTokens.Typography.body(16))
                        .foregroundStyle(Color.white.opacity(0.95))
                }
                .padding(20)
            }
            .padding()
        }
    }
}
#endif
