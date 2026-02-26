import SwiftUI

private struct DictionaryEntry: Identifiable, Hashable {
    let id = UUID()
    let name: String
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
    @State private var favorites: Set<String> = ["Deniz", "Balık"]
    @State private var recentNames: [String] = ["Ay", "Balık"]

    private let entries: [DictionaryEntry] = [
        .init(name: "Anahtar", icon: "key.fill", letter: "A"),
        .init(name: "Ayakkabı", icon: "shoe.2.fill", letter: "A"),
        .init(name: "Balık", icon: "fish.fill", letter: "B"),
        .init(name: "Deniz", icon: "water.waves", letter: "D"),
        .init(name: "Fil", icon: "tortoise.fill", letter: "F"),
        .init(name: "Gölge", icon: "moon.fill", letter: "G"),
        .init(name: "Kapı", icon: "door.left.hand.open", letter: "K"),
        .init(name: "Kuş", icon: "bird.fill", letter: "K"),
        .init(name: "Merdiven", icon: "stairs", letter: "M"),
        .init(name: "Yıldız", icon: "sparkles", letter: "Y")
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

            Text("Rüya Sözlüğü")
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
            TextField("Sembol Ara...", text: $searchText)
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
            segmentButton(title: "Sembol", isActive: mode == .symbol) {
                mode = .symbol
            }
            segmentButton(title: "Favoriler", isActive: mode == .favorite) {
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
                        toggleRecent(entry.name)
                    } label: {
                        HStack(spacing: 12) {
                            iconBadge(for: entry.icon)
                            Text(entry.name)
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
            segmentButton(title: "Favoriler", isActive: recentMode == .favorite) {
                recentMode = .favorite
            }
            segmentButton(title: "Son Bakılanlar", isActive: recentMode == .recent) {
                recentMode = .recent
            }
        }
        .padding(5)
        .background(Color.white.opacity(0.13))
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
    }

    private var recentPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Son Bakılanlar")
                .font(DreamTheme.medium(22))
                .foregroundStyle(Color.white)

            HStack(spacing: 10) {
                ForEach(recentVisible.prefix(4), id: \.self) { name in
                    iconBadge(for: iconForName(name))
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
            base = entries.filter { favorites.contains($0.name) }
        }

        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if trimmed.isEmpty { return base }
        return base.filter { $0.name.lowercased().contains(trimmed) }
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

    private func iconForName(_ name: String) -> String {
        entries.first(where: { $0.name == name })?.icon ?? "sparkles"
    }
}
