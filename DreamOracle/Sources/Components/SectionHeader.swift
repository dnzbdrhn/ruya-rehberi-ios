import SwiftUI

struct SectionHeader<Trailing: View>: View {
    let titleKey: LocalizedStringKey
    @ViewBuilder let trailing: () -> Trailing

    @Environment(\.colorScheme) private var colorScheme

    init(_ titleKey: LocalizedStringKey, @ViewBuilder trailing: @escaping () -> Trailing) {
        self.titleKey = titleKey
        self.trailing = trailing
    }

    init(_ titleKey: LocalizedStringKey) where Trailing == EmptyView {
        self.titleKey = titleKey
        self.trailing = { EmptyView() }
    }

    var body: some View {
        let colors = Theme.colors(for: colorScheme)

        HStack(alignment: .center, spacing: DesignTokens.Spacing.sm) {
            Text(titleKey)
                .font(DesignTokens.Typography.title(20))
                .foregroundStyle(colors.textPrimary)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .minimumScaleFactor(0.9)

            Spacer(minLength: DesignTokens.Spacing.xs)
            trailing()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
    }
}

#if DEBUG
struct SectionHeader_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            MysticalBackgroundView()
            VStack(spacing: 12) {
                SectionHeader("design.preview.section.cards")
                SectionHeader("design.preview.section.buttons") {
                    SecondaryButton(titleKey: "design.preview.trailing.action", action: {})
                        .frame(width: 132)
                }
            }
            .padding()
        }
    }
}
#endif
