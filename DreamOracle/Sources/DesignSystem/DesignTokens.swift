import SwiftUI

enum DesignTokens {
    static let minimumTapSize: CGFloat = 44

    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 28
    }

    enum Radius {
        static let sm: CGFloat = 10
        static let md: CGFloat = 16
        static let lg: CGFloat = 22
        static let xl: CGFloat = 28
        static let pill: CGFloat = 999
    }

    enum Glass {
        static let cardCorner: CGFloat = 30
        static let pillCorner: CGFloat = 30
        static let chipCorner: CGFloat = 20
        static let overlayCorner: CGFloat = 28

        static let borderWidth: CGFloat = 1.2
        static let borderOpacity: CGFloat = 0.20
        static let sheenOpacity: CGFloat = 0.16
        static let frostOpacity: CGFloat = 0.13
        static let grainOpacity: CGFloat = 0.06

        static let glowRadius: CGFloat = 16
        static let glowYOffset: CGFloat = 6
    }

    enum Stroke {
        static let hairline: CGFloat = 0.75
        static let regular: CGFloat = 1
        static let emphasis: CGFloat = 1.5
    }

    enum Glow {
        static let soft: CGFloat = 10
        static let medium: CGFloat = 18
        static let strong: CGFloat = 28
    }

    enum Shadow {
        static let cardRadius: CGFloat = 18
        static let cardYOffset: CGFloat = 8
        static let floatingRadius: CGFloat = 12
        static let floatingYOffset: CGFloat = 4
    }

    enum Typography {
        static func heading(_ size: CGFloat) -> Font {
            .custom("AvenirNext-Bold", size: size, relativeTo: .title2)
        }

        static func title(_ size: CGFloat) -> Font {
            .custom("AvenirNext-DemiBold", size: size, relativeTo: .title3)
        }

        static func body(_ size: CGFloat) -> Font {
            .custom("AvenirNext-Regular", size: size, relativeTo: .body)
        }

        static func label(_ size: CGFloat) -> Font {
            .custom("AvenirNext-Medium", size: size, relativeTo: .callout)
        }
    }

    enum Motion {
        static let quick = Animation.easeOut(duration: 0.18)
        static let standard = Animation.easeInOut(duration: 0.28)
        static let breathing = Animation.easeInOut(duration: 1.4).repeatForever(autoreverses: true)
    }
}
