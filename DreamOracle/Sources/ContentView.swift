import SwiftUI
import UIKit
import ImageIO

private enum DreamTab: Int, CaseIterable, Identifiable {
    case home = 0
    case calendar = 1
    case dreams = 2
    case profile = 3

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .home: return String(localized: "tab.home")
        case .calendar: return String(localized: "tab.calendar")
        case .dreams: return String(localized: "tab.dreams")
        case .profile: return String(localized: "tab.profile")
        }
    }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .calendar: return "calendar"
        case .dreams: return "books.vertical.fill"
        case .profile: return "person.fill"
        }
    }
}

struct ContentView: View {
    @ObservedObject var viewModel: DreamInterpreterViewModel
    @EnvironmentObject private var paywallPresenter: PaywallPresenter
    @State private var selectedTab: DreamTab = .home
    @State private var showComposer = false
    @State private var composerStartsWithVoice = false
    @State private var showInterpretation = false
    @State private var openInterpretationAfterComposer = false

    var body: some View {
        GeometryReader { geo in
            let progress = swipeProgress()

            ZStack {
                DreamPanoramaBackground(progress: progress)
                    .animation(.interactiveSpring(response: 0.42, dampingFraction: 0.90), value: selectedTab)

                TabView(selection: $selectedTab) {
                    pageContainer {
                        DreamHomeView(
                            viewModel: viewModel,
                            onOpenComposer: {
                                composerStartsWithVoice = false
                                showComposer = true
                            },
                            onOpenVoiceComposer: {
                                composerStartsWithVoice = true
                                showComposer = true
                            },
                            onOpenInterpretation: { recordID in
                                viewModel.selectRecord(recordID)
                                showInterpretation = true
                            }
                        )
                    }
                    .tag(DreamTab.home)

                    pageContainer {
                        DreamCalendarView(
                            viewModel: viewModel,
                            onOpenInterpretation: { recordID in
                                viewModel.selectRecord(recordID)
                                showInterpretation = true
                            }
                        )
                    }
                    .tag(DreamTab.calendar)

                    pageContainer {
                        DreamJournalHubView(
                            viewModel: viewModel,
                            onOpenInterpretation: { recordID in
                                viewModel.selectRecord(recordID)
                                showInterpretation = true
                            }
                        )
                    }
                    .tag(DreamTab.dreams)

                    pageContainer {
                        DreamProfileView(viewModel: viewModel)
                    }
                    .tag(DreamTab.profile)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .background(Color.clear)
            }
            .safeAreaInset(edge: .bottom) {
                DreamBottomTabBar(
                    selectedTab: $selectedTab,
                    barWidth: max(0, geo.size.width - 40)
                )
                .padding(.bottom, max(geo.safeAreaInsets.bottom * 0.12, 2))
            }
        }
        .fullScreenCover(isPresented: $showComposer) {
            NavigationStack {
                DreamComposerView(viewModel: viewModel, startInVoiceMode: composerStartsWithVoice) {
                    openInterpretationAfterComposer = true
                }
            }
            .onDisappear {
                if openInterpretationAfterComposer {
                    openInterpretationAfterComposer = false
                    showInterpretation = true
                }
            }
        }
        .fullScreenCover(isPresented: $showInterpretation) {
            NavigationStack {
                DreamInterpretationView(
                    viewModel: viewModel,
                    showsBackButton: true,
                    onBack: { showInterpretation = false }
                )
            }
        }
        .sheet(
            isPresented: Binding(
                get: { paywallPresenter.isShowing && !showComposer && !showInterpretation },
                set: { isPresented in
                    if !isPresented {
                        paywallPresenter.dismiss()
                    }
                }
            )
        ) {
            NavigationStack {
                PaywallView()
            }
            .presentationDragIndicator(.visible)
        }
    }

    private func pageContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .environment(\.usesSharedTabPanoramaBackground, true)
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 66)
            }
            .background(Color.clear)
    }

    private func swipeProgress() -> CGFloat {
        let lastIndex = max(CGFloat(DreamTab.allCases.count - 1), 1)
        return min(max(CGFloat(selectedTab.rawValue), 0), lastIndex) / lastIndex
    }
}

private struct DreamPanoramaBackground: View {
    let progress: CGFloat
    private static let cachedPanorama: UIImage? = {
        let candidates = [
            ("arkaplan_new", "png"),
            ("arkaplan", "png")
        ]

        var selectedPath: String?
        for (name, ext) in candidates {
            if let path = Bundle.main.path(forResource: name, ofType: ext) {
                selectedPath = path
                break
            }
        }
        guard let path = selectedPath else { return nil }
        guard let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil) else {
            return UIImage(contentsOfFile: path)
        }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: 2400,
            kCGImageSourceCreateThumbnailWithTransform: true
        ]

        let baseImage: UIImage?
        if let cgThumb = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) {
            baseImage = UIImage(cgImage: cgThumb)
        } else {
            baseImage = UIImage(contentsOfFile: path)
        }

        guard let image = baseImage else { return nil }

        // PNG alpha kanalinda olasi seffaf bantlari, tema rengi ile opaklastir.
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = image.scale
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        return renderer.image { ctx in
            UIColor(red: 0.10, green: 0.15, blue: 0.37, alpha: 1.0).setFill()
            ctx.fill(CGRect(origin: .zero, size: image.size))
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }()

    var body: some View {
        GeometryReader { geo in
            let clamped = min(max(progress, 0), 1)
            let aspectRatio: CGFloat = {
                guard let image = Self.cachedPanorama, image.size.height > 0 else {
                    return 16.0 / 9.0
                }
                return max(image.size.width / image.size.height, 1.2)
            }()
            let canvasHeight = geo.size.height + geo.safeAreaInsets.top + geo.safeAreaInsets.bottom + 220
            let imageWidth = max(geo.size.width, canvasHeight * aspectRatio)
            let travel = max(imageWidth - geo.size.width, 0)

            ZStack {
                if let panorama = Self.cachedPanorama {
                    Image(uiImage: panorama)
                        .resizable()
                        .scaledToFill()
                        .frame(width: imageWidth, height: canvasHeight)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .offset(x: -travel * clamped)
                } else {
                    DreamBackground()
                }

                LinearGradient(
                    colors: [
                        Color(red: 0.07, green: 0.10, blue: 0.30).opacity(0.44),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .center
                )
                .ignoresSafeArea()

                LinearGradient(
                    colors: [
                        Color.clear,
                        Color(red: 0.09, green: 0.11, blue: 0.32).opacity(0.26)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            }
            .ignoresSafeArea()
        }
    }
}

private struct DreamBottomTabBar: View {
    @Binding var selectedTab: DreamTab
    let barWidth: CGFloat

    private var tabs: [DreamTab] { DreamTab.allCases }
    private var spacing: CGFloat { 8 }
    private var horizontalPadding: CGFloat { 10 }

    private var segmentWidth: CGFloat {
        let count = CGFloat(max(tabs.count, 1))
        let totalSpacing = spacing * (count - 1)
        let available = max(barWidth - (horizontalPadding * 2) - totalSpacing, 1)
        return available / count
    }

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(tabs) { tab in
                tabButton(tab)
            }
        }
        .frame(width: barWidth)
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.84))
        )
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.62), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
    }

    private func tabButton(_ tab: DreamTab) -> some View {
        Button {
            withAnimation(.interactiveSpring(response: 0.38, dampingFraction: 0.86, blendDuration: 0.2)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: tab.icon)
                    .font(.system(size: 21, weight: .semibold))
                Text(tab.title)
                    .font(DreamTheme.medium(13))
                    .lineLimit(1)
            }
            .foregroundStyle(
                selectedTab == tab
                ? DreamTheme.textDark
                : Color(red: 0.24, green: 0.20, blue: 0.42).opacity(0.78)
            )
            .frame(width: segmentWidth)
            .frame(minHeight: 52)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(selectedTab == tab ? Color(red: 0.68, green: 0.60, blue: 0.86).opacity(0.65) : .clear)
            )
        }
        .buttonStyle(.plain)
    }
}
