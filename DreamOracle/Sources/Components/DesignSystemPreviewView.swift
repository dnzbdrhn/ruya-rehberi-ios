#if DEBUG
import SwiftUI

struct DesignSystemPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var showsLocked = true
    @State private var selectedIntensity: GlassIntensity = .medium

    var body: some View {
        ZStack {
            MysticalBackgroundView(prefersAsset: true, themeStyle: .night, emphasizedReadableZone: .middle)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                    topBar
                    intensityControls
                    cardSamples
                    tabBarSample
                    chipSamples
                    buttonSamples
                    iconSamples
                    overlaySample
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.top, DesignTokens.Spacing.md)
                .padding(.bottom, DesignTokens.Spacing.xl)
            }

            LoadingOverlay(isVisible: isLoading, messageKey: "design.preview.loading")
        }
        .environment(\.glassIntensity, selectedIntensity)
        .navigationBarHidden(true)
    }

    private var topBar: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                Text(String(localized: "design.preview.title"))
                    .font(DesignTokens.Typography.heading(28))
                    .foregroundStyle(Color.white.opacity(0.96))
                Text(String(localized: "design.preview.subtitle"))
                    .font(DesignTokens.Typography.body(14))
                    .foregroundStyle(Color.white.opacity(0.82))
            }
            Spacer()
            SecondaryButton(titleKey: "common.close") {
                dismiss()
            }
            .frame(width: 112)
        }
    }

    private var intensityControls: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            SectionHeader("design.preview.intensity.title")
            GlassSurface(style: .pill, themeStyle: .night) {
                Picker(
                    String(localized: "design.preview.intensity.title"),
                    selection: $selectedIntensity
                ) {
                    ForEach(GlassIntensity.allCases) { intensity in
                        Text(String(localized: String.LocalizationValue(intensity.localizationKey)))
                            .tag(intensity)
                    }
                }
                .pickerStyle(.segmented)
                .padding(DesignTokens.Spacing.sm)
            }
        }
    }

    private var cardSamples: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            SectionHeader("design.preview.section.cards")
            GlassSurface(style: .card, themeStyle: .night) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text(String(localized: "design.preview.card.title"))
                        .font(DesignTokens.Typography.title(24))
                        .foregroundStyle(Color.white.opacity(0.95))
                        .lineLimit(2)
                    Text(String(localized: "design.preview.sample.body"))
                        .font(DesignTokens.Typography.body(16))
                        .foregroundStyle(Color.white.opacity(0.82))
                        .lineLimit(3)
                    PrimaryCTAButton(
                        titleKey: "design.preview.cta.primary",
                        systemImage: "sparkles",
                        action: {}
                    )
                }
                .padding(DesignTokens.Spacing.lg)
            }
        }
    }

    private var tabBarSample: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            SectionHeader("design.preview.section.tabbar")
            GlassSurface(style: .pill, themeStyle: .night, cornerRadius: 31) {
                HStack(spacing: 10) {
                    previewTab(icon: "house.fill", title: String(localized: "tab.home"), selected: true)
                    previewTab(icon: "calendar", title: String(localized: "tab.calendar"), selected: false)
                    previewTab(icon: "books.vertical.fill", title: String(localized: "tab.dreams"), selected: false)
                    previewTab(icon: "person.fill", title: String(localized: "tab.profile"), selected: false)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
            }
        }
    }

    private var chipSamples: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            SectionHeader("design.preview.section.chips")
            HStack(spacing: 10) {
                SecondaryButton(
                    titleKey: "design.preview.chip.one",
                    systemImage: "sparkles",
                    surfaceStyle: .chip,
                    action: {}
                )
                .frame(width: 136)

                SecondaryButton(
                    titleKey: "design.preview.chip.two",
                    systemImage: "moon.stars.fill",
                    surfaceStyle: .chip,
                    action: {}
                )
                .frame(width: 124)
            }
        }
    }

    private var buttonSamples: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            SectionHeader("design.preview.section.buttons")
            PrimaryCTAButton(
                titleKey: "design.preview.cta.primary",
                systemImage: "sparkles"
            ) {
                simulateLoading()
            }
            SecondaryButton(
                titleKey: "design.preview.cta.secondary",
                systemImage: "moon.stars.fill"
            ) {
                withAnimation(DesignTokens.Motion.standard) {
                    showsLocked.toggle()
                }
            }
        }
    }

    private var iconSamples: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            SectionHeader("design.preview.section.icons")
            HStack(spacing: DesignTokens.Spacing.sm) {
                GlowIconButton(
                    systemImage: "mic.fill",
                    accessibilityLabelKey: "design.preview.icon.mic"
                ) {}
                GlowIconButton(
                    systemImage: "sparkles",
                    accessibilityLabelKey: "design.preview.icon.sparkle"
                ) {}
                GlowIconButton(
                    systemImage: "plus",
                    accessibilityLabelKey: "design.preview.icon.plus"
                ) {}
            }
        }
    }

    @ViewBuilder
    private var overlaySample: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            SectionHeader("design.preview.section.locked")

            if showsLocked {
                LockedPreviewOverlay(
                    titleKey: "design.preview.locked.title",
                    subtitleKey: "design.preview.locked.message"
                ) {
                    Text(String(localized: "design.preview.sample.body"))
                        .font(DesignTokens.Typography.body(15))
                        .foregroundStyle(Color.white.opacity(0.88))
                        .frame(maxWidth: .infinity, minHeight: 160, alignment: .topLeading)
                        .padding(DesignTokens.Spacing.md)
                        .background(Color.white.opacity(0.10))
                } callToAction: {
                    PrimaryCTAButton(
                        titleKey: "design.preview.cta.primary",
                        systemImage: "sparkles",
                        action: {}
                    )
                }
                .frame(height: 220)
            } else {
                GlassCard {
                    Text(String(localized: "design.preview.locked.hidden"))
                        .font(DesignTokens.Typography.body(14))
                        .foregroundStyle(Color.white.opacity(0.86))
                }
            }
        }
    }

    private func previewTab(icon: String, title: String, selected: Bool) -> some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
            Text(title)
                .font(DesignTokens.Typography.label(12.5))
                .lineLimit(1)
        }
        .foregroundStyle(selected ? Color.white.opacity(0.98) : Color.white.opacity(0.72))
        .frame(maxWidth: .infinity)
        .frame(minHeight: 52)
        .background(
            Capsule()
                .fill(selected ? Color.white.opacity(0.18) : Color.clear)
        )
    }

    private func simulateLoading() {
        guard !isLoading else { return }
        isLoading = true
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

struct DesignSystemPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            DesignSystemPreviewView()
        }
    }
}
#endif
