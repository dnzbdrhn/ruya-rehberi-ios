import SwiftUI

private struct DictionaryEntry: Identifiable, Hashable {
    let id = UUID()
    let nameKey: String
    let icon: String
    let letter: String
}

private enum DictionaryMode {
    case symbol
    case favorite
}

private enum RecentMode {
    case favorite
    case recent
}

struct DreamDictionaryView: View {
    let onOpenInterpretation: ((UUID) -> Void)?

    @State private var searchText = ""
    @State private var mode: DictionaryMode = .symbol
    @State private var recentMode: RecentMode = .recent
    @State private var favorites: Set<String> = ["dictionary.entry.sea", "dictionary.entry.fish"]
    @State private var recentNames: [String] = ["dictionary.entry.moon", "dictionary.entry.fish"]

    private let entries: [DictionaryEntry] = [
        .init(nameKey: "dictionary.entry.key", icon: "key.fill", letter: "A"),
        .init(nameKey: "dictionary.entry.shoe", icon: "shoe.2.fill", letter: "A"),
        .init(nameKey: "dictionary.entry.fish", icon: "fish.fill", letter: "B"),
        .init(nameKey: "dictionary.entry.sea", icon: "water.waves", letter: "D"),
        .init(nameKey: "dictionary.entry.elephant", icon: "tortoise.fill", letter: "F"),
        .init(nameKey: "dictionary.entry.shadow", icon: "moon.fill", letter: "G"),
        .init(nameKey: "dictionary.entry.door", icon: "door.left.hand.open", letter: "K"),
        .init(nameKey: "dictionary.entry.bird", icon: "bird.fill", letter: "K"),
        .init(nameKey: "dictionary.entry.stairs", icon: "stairs", letter: "M"),
        .init(nameKey: "dictionary.entry.star", icon: "sparkles", letter: "Y"),
        .init(nameKey: "dictionary.entry.moon", icon: "moon.stars.fill", letter: "A")
    ]

    init(onOpenInterpretation: ((UUID) -> Void)? = nil) {
        self.onOpenInterpretation = onOpenInterpretation
    }

    var body: some View {
        ZStack {
            DreamBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    topBar
                    searchBar
                    topSegment
                    dictionaryPanel
                    lowerSegment
                    recentPanel
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 28)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var topBar: some View {
        HStack {
            Image(systemName: "chevron.left")
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.94))

            Spacer()

            Text(String(localized: "dictionary.title"))
                .font(DreamTheme.heading(34 * 0.82))
                .foregroundStyle(Color.white)

            Spacer()
            Color.clear.frame(width: 18, height: 18)
        }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.white.opacity(0.6))
            TextField(String(localized: "dictionary.search.placeholder"), text: $searchText)
                .font(DreamTheme.body(18))
                .foregroundStyle(Color.white.opacity(0.9))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .background(Color.white.opacity(0.17))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    }

    private var topSegment: some View {
        HStack(spacing: 8) {
            segmentButton(title: String(localized: "dictionary.segment.symbol"), isActive: mode == .symbol) {
                mode = .symbol
            }
            segmentButton(title: String(localized: "dictionary.segment.favorites"), isActive: mode == .favorite) {
                mode = .favorite
            }
        }
        .padding(5)
        .background(Color.white.opacity(0.13))
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
    }

    private var dictionaryPanel: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                ForEach(filteredEntries.indices, id: \.self) { index in
                    let entry = filteredEntries[index]
                    Button {
                        toggleRecent(entry.nameKey)
                    } label: {
                        HStack(spacing: 12) {
                            iconBadge(for: entry.icon)
                            Text(localizedEntryName(entry.nameKey))
                                .font(DreamTheme.medium(19))
                                .foregroundStyle(Color.white.opacity(0.97))
                            Spacer()
                        }
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)

                    if index < filteredEntries.count - 1 {
                        Divider().background(Color.white.opacity(0.16))
                    }
                }
            }
            .padding(12)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )

            VStack(spacing: 4) {
                ForEach(alphabet, id: \.self) { letter in
                    Text(letter)
                        .font(DreamTheme.body(16))
                        .foregroundStyle(Color.white.opacity(0.72))
                }
            }
            .padding(.top, 2)
        }
    }

    private var lowerSegment: some View {
        HStack(spacing: 8) {
            segmentButton(title: String(localized: "dictionary.segment.favorites"), isActive: recentMode == .favorite) {
                recentMode = .favorite
            }
            segmentButton(title: String(localized: "dictionary.segment.recent"), isActive: recentMode == .recent) {
                recentMode = .recent
            }
        }
        .padding(5)
        .background(Color.white.opacity(0.13))
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
    }

    private var recentPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "dictionary.recent.title"))
                .font(DreamTheme.medium(22))
                .foregroundStyle(Color.white)

            HStack(spacing: 10) {
                ForEach(recentVisible.prefix(4), id: \.self) { nameKey in
                    iconBadge(for: iconForNameKey(nameKey))
                        .frame(width: 50, height: 50)
                }
                Spacer()
            }
        }
        .dreamCard(light: false, cornerRadius: 18)
    }

    private var filteredEntries: [DictionaryEntry] {
        let base: [DictionaryEntry]
        switch mode {
        case .symbol:
            base = entries
        case .favorite:
            base = entries.filter { favorites.contains($0.nameKey) }
        }

        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if trimmed.isEmpty { return base }
        return base.filter { localizedEntryName($0.nameKey).lowercased().contains(trimmed) }
    }

    private var recentVisible: [String] {
        if recentMode == .favorite {
            return Array(favorites)
        }
        return recentNames
    }

    private var alphabet: [String] {
        Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ").map { String($0) }
    }

    private func segmentButton(title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(DreamTheme.medium(18))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .foregroundStyle(isActive ? DreamTheme.textDark : Color.white.opacity(0.83))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(isActive ? Color.white.opacity(0.8) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func iconBadge(for symbol: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.14))
            Image(systemName: symbol)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(DreamTheme.goldStart)
        }
    }

    private func toggleRecent(_ name: String) {
        recentNames.removeAll(where: { $0 == name })
        recentNames.insert(name, at: 0)
        recentNames = Array(recentNames.prefix(8))
    }

    private func iconForNameKey(_ nameKey: String) -> String {
        entries.first(where: { $0.nameKey == nameKey })?.icon ?? "sparkles"
    }

    private func localizedEntryName(_ key: String) -> String {
        String(localized: String.LocalizationValue(key))
    }
}
