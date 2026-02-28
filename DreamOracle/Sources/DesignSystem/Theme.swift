import SwiftUI

enum AppThemeStyle {
    case automatic
    case night
    case light
}

enum Theme {
    struct Colors {
        let backgroundTop: Color
        let backgroundBottom: Color
        let surface: Color
        let surfaceElevated: Color
        let textPrimary: Color
        let textSecondary: Color
        let accentGold: Color
        let accentViolet: Color
        let danger: Color
        let success: Color
        let border: Color
        let glow: Color
    }

    static func colors(for scheme: ColorScheme, style: AppThemeStyle = .night) -> Colors {
        switch style {
        case .night:
            return night
        case .light:
            return day
        case .automatic:
            return scheme == .dark ? night : day
        }
    }

    static func backgroundGradient(_ colors: Colors) -> LinearGradient {
        LinearGradient(
            colors: [colors.backgroundTop, colors.backgroundBottom],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static func goldGradient(_ colors: Colors) -> LinearGradient {
        LinearGradient(
            colors: [colors.accentGold.opacity(0.98), Color(red: 0.82, green: 0.72, blue: 0.56)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func violetGradient(_ colors: Colors) -> LinearGradient {
        LinearGradient(
            colors: [colors.accentViolet.opacity(0.86), colors.backgroundTop.opacity(0.82)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func glassHighlight(_ colors: Colors) -> LinearGradient {
        LinearGradient(
            colors: [Color.white.opacity(0.24), Color.white.opacity(0.04)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private static let night = Colors(
        backgroundTop: Color(red: 0.08, green: 0.12, blue: 0.30),
        backgroundBottom: Color(red: 0.16, green: 0.12, blue: 0.31),
        surface: Color(red: 0.16, green: 0.20, blue: 0.40).opacity(0.72),
        surfaceElevated: Color(red: 0.22, green: 0.24, blue: 0.47).opacity(0.82),
        textPrimary: Color.white.opacity(0.96),
        textSecondary: Color.white.opacity(0.78),
        accentGold: Color(red: 0.91, green: 0.81, blue: 0.67),
        accentViolet: Color(red: 0.63, green: 0.53, blue: 0.89),
        danger: Color(red: 0.92, green: 0.42, blue: 0.41),
        success: Color(red: 0.41, green: 0.84, blue: 0.61),
        border: Color.white.opacity(0.20),
        glow: Color(red: 0.91, green: 0.81, blue: 0.67).opacity(0.50)
    )

    private static let day = Colors(
        backgroundTop: Color(red: 0.89, green: 0.92, blue: 0.97),
        backgroundBottom: Color(red: 0.80, green: 0.84, blue: 0.94),
        surface: Color.white.opacity(0.74),
        surfaceElevated: Color.white.opacity(0.90),
        textPrimary: Color(red: 0.16, green: 0.18, blue: 0.30),
        textSecondary: Color(red: 0.22, green: 0.25, blue: 0.38).opacity(0.78),
        accentGold: Color(red: 0.84, green: 0.67, blue: 0.38),
        accentViolet: Color(red: 0.50, green: 0.40, blue: 0.78),
        danger: Color(red: 0.82, green: 0.29, blue: 0.30),
        success: Color(red: 0.18, green: 0.66, blue: 0.41),
        border: Color.white.opacity(0.62),
        glow: Color(red: 0.84, green: 0.72, blue: 0.56).opacity(0.34)
    )
}
