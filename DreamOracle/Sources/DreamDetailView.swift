import SwiftUI

private enum DreamJournalTopTab: String, CaseIterable, Identifiable {
    case dreams = "Rüyalar"
    case objects = "Rüya Nesneleri"

    var id: String { rawValue }
}

private enum DreamObjectCategory: CaseIterable, Identifiable {
    case people
    case actions
    case places
    case emotions
    case animals
    case objects
    case themes
    case weather

    var id: String { title }

    var title: String {
        switch self {
        case .people: return "İnsanlar"
        case .actions: return "Eylemler"
        case .places: return "Yerler"
        case .emotions: return "Duygular"
        case .animals: return "Hayvanlar"
        case .objects: return "Nesneler"
        case .themes: return "Temalar"
        case .weather: return "Hava Durumu"
        }
    }

    var subtitle: String {
        switch self {
        case .people: return "Rüyalardaki kişiler ve figürler"
        case .actions: return "Tekrarlayan davranış ve hareketler"
        case .places: return "Mekanlar ve sahneler"
        case .emotions: return "Duygusal ipuçları"
        case .animals: return "Hayvan arketipleri"
        case .objects: return "Sembolik nesneler"
        case .themes: return "Ana tematik örüntüler"
        case .weather: return "Atmosfer ve hava halleri"
        }
    }

    var icon: String {
        switch self {
        case .people: return "person.2.fill"
        case .actions: return "bolt.fill"
        case .places: return "mappin.and.ellipse"
        case .emotions: return "heart.fill"
        case .animals: return "pawprint.fill"
        case .objects: return "shippingbox.fill"
        case .themes: return "lightbulb.fill"
        case .weather: return "cloud.fill"
        }
    }

    var accent: Color {
        switch self {
        case .people: return Color(red: 0.98, green: 0.42, blue: 0.67)
        case .actions: return Color(red: 0.95, green: 0.77, blue: 0.33)
        case .places: return Color(red: 0.47, green: 0.85, blue: 0.90)
        case .emotions: return Color(red: 0.97, green: 0.49, blue: 0.59)
        case .animals: return Color(red: 0.61, green: 0.84, blue: 0.45)
        case .objects: return Color(red: 0.52, green: 0.72, blue: 0.98)
        case .themes: return Color(red: 0.92, green: 0.60, blue: 0.43)
        case .weather: return Color(red: 0.70, green: 0.74, blue: 0.84)
        }
    }

    var terms: [DreamCategoryTerm] {
        switch self {
        case .people:
            return [
                .init(label: "İnsan", aliases: ["insan", "kişi", "kisi", "figür", "figur"]),
                .init(label: "Anne", aliases: ["anne"]),
                .init(label: "Baba", aliases: ["baba"]),
                .init(label: "Çocuk", aliases: ["cocuk", "çocuk"]),
                .init(label: "Kadın", aliases: ["kadin", "kadın"]),
                .init(label: "Erkek", aliases: ["erkek"]),
                .init(label: "Arkadaş", aliases: ["arkadas", "arkadaş"]),
                .init(label: "Sevgili", aliases: ["sevgili"]),
                .init(label: "Öğretmen", aliases: ["ogretmen", "öğretmen"]),
                .init(label: "Yabancı", aliases: ["yabanci", "yabancı"])
            ]
        case .actions:
            return [
                .init(label: "Koşmak", aliases: ["kos", "koş", "koşmak", "kosmak", "kosuyor", "koşuyor", "kostu", "koştu"]),
                .init(label: "Uçmak", aliases: ["uc", "uç", "ucmak", "uçmak", "ucuyor", "uçuyor", "uctu", "uçtu"]),
                .init(label: "Düşmek", aliases: ["dus", "düş", "dusmek", "düşmek", "dustu", "düştü", "dusuyor", "düşüyor"]),
                .init(label: "Kaçmak", aliases: ["kac", "kaç", "kacmak", "kaçmak", "kacti", "kaçtı", "kaciyor", "kaçıyor"]),
                .init(label: "Yüzmek", aliases: ["yuz", "yüz", "yuzmek", "yüzmek", "yuzdu", "yüzdü", "yuzuyor", "yüzüyor"]),
                .init(label: "Konuşmak", aliases: ["konus", "konuş", "konusmak", "konuşmak", "konustu", "konuştu", "konusuyor", "konuşuyor"]),
                .init(label: "Aramak", aliases: ["ara", "aramak", "ariyor", "arıyor", "aradi", "aradı"]),
                .init(label: "Saklanmak", aliases: ["saklan", "saklanmak", "saklandi", "saklandı"]),
                .init(label: "Takip", aliases: ["takip", "kovala", "kovalamak", "kovaladi", "kovaladı"]),
                .init(label: "İçmek", aliases: ["icmek", "içmek", "iciyorum", "içiyorum"])
            ]
        case .places:
            return [
                .init(label: "Ev", aliases: ["ev", "evde", "eve", "evin", "evim"]),
                .init(label: "Oda", aliases: ["oda", "odada", "odaya", "odam"]),
                .init(label: "Okul", aliases: ["okul", "okulda"]),
                .init(label: "Sokak", aliases: ["sokak", "sokakta"]),
                .init(label: "Yol", aliases: ["yol", "yolda", "yola"]),
                .init(label: "Şehir", aliases: ["sehir", "şehir", "sehirde", "şehirde"]),
                .init(label: "Orman", aliases: ["orman", "ormanda"]),
                .init(label: "Dağ", aliases: ["dag", "dağ", "dagda", "dağda"]),
                .init(label: "Deniz", aliases: ["deniz", "denizde", "okyanus", "sahil"]),
                .init(label: "Köprü", aliases: ["kopru", "köprü", "koprude", "köprüde"]),
                .init(label: "Hastane", aliases: ["hastane", "hastanede"]),
                .init(label: "Otel", aliases: ["otel", "otelde"])
            ]
        case .emotions:
            return [
                .init(label: "Korku", aliases: ["korku", "korkmak", "korku dolu"]),
                .init(label: "Kaygı", aliases: ["kaygi", "kaygı", "endise", "endişe"]),
                .init(label: "Hüzün", aliases: ["uzgun", "üzgün", "huzun", "hüzün"]),
                .init(label: "Mutluluk", aliases: ["mutlu", "mutluluk", "sevinç", "sevinc"]),
                .init(label: "Öfke", aliases: ["ofke", "öfke", "kizgin", "kızgın"]),
                .init(label: "Huzur", aliases: ["huzur", "huzurlu", "sakin"]),
                .init(label: "Panik", aliases: ["panik", "dehset", "dehşet"]),
                .init(label: "Yalnızlık", aliases: ["yalniz", "yalnız", "yalnizlik", "yalnızlık"]),
                .init(label: "Özlem", aliases: ["ozlem", "özlem"])
            ]
        case .animals:
            return [
                .init(label: "Kuş", aliases: ["kus", "kuş", "kartal", "serce", "serçe"]),
                .init(label: "Kedi", aliases: ["kedi"]),
                .init(label: "Köpek", aliases: ["kopek", "köpek"]),
                .init(label: "Fil", aliases: ["fil"]),
                .init(label: "Balık", aliases: ["balik", "balık"]),
                .init(label: "Yılan", aliases: ["yilan", "yılan"]),
                .init(label: "At", aliases: ["at"]),
                .init(label: "Aslan", aliases: ["aslan"]),
                .init(label: "Kurt", aliases: ["kurt", "wolf"]),
                .init(label: "Böcek", aliases: ["bocek", "böcek"])
            ]
        case .objects:
            return [
                .init(label: "Telefon", aliases: ["telefon", "cep telefonu"]),
                .init(label: "Anahtar", aliases: ["anahtar"]),
                .init(label: "Araba", aliases: ["araba", "otomobil"]),
                .init(label: "Kapı", aliases: ["kapi", "kapı"]),
                .init(label: "Ayna", aliases: ["ayna"]),
                .init(label: "Saat", aliases: ["saat"]),
                .init(label: "Cam", aliases: ["cam", "pencere"]),
                .init(label: "Su", aliases: ["su", "suyu", "sudan", "suda"]),
                .init(label: "Bardak", aliases: ["bardak"]),
                .init(label: "Sürahi", aliases: ["surahi", "sürahi"]),
                .init(label: "Masa", aliases: ["masa", "sehpa"]),
                .init(label: "Yatak", aliases: ["yatak", "yastik", "yastık"])
            ]
        case .themes:
            return [
                .init(label: "Gölge", aliases: ["golge", "gölge"]),
                .init(label: "Bireyleşme", aliases: ["bireylesme", "bireyleşme"]),
                .init(label: "Anima/Animus", aliases: ["anima", "animus", "anima/animus"]),
                .init(label: "Persona", aliases: ["persona"]),
                .init(label: "Dönüşüm", aliases: ["donusum", "dönüşüm", "donus", "dönüş"]),
                .init(label: "Özgürlük", aliases: ["ozgurluk", "özgürlük"]),
                .init(label: "Yüzleşme", aliases: ["yuzlesme", "yüzleşme", "yuzles", "yüzleş"]),
                .init(label: "Denge", aliases: ["denge"]),
                .init(label: "Arayış", aliases: ["arayis", "arayış"]),
                .init(label: "Potansiyel", aliases: ["potansiyel"]),
                .init(label: "İçsel Çatışma", aliases: ["icsel catisma", "içsel çatışma"])
            ]
        case .weather:
            return [
                .init(label: "Yağmur", aliases: ["yagmur", "yağmur", "yagmurlu", "yağmurlu"]),
                .init(label: "Fırtına", aliases: ["firtina", "fırtına"]),
                .init(label: "Kar", aliases: ["kar", "karli", "karlı"]),
                .init(label: "Rüzgar", aliases: ["ruzgar", "rüzgar", "ruzgarli", "rüzgarlı"]),
                .init(label: "Güneş", aliases: ["gunes", "güneş"]),
                .init(label: "Ay", aliases: ["ay", "ayisigi", "ayışığı", "ay ışığı"]),
                .init(label: "Gece", aliases: ["gece", "geceleyin"]),
                .init(label: "Gökyüzü", aliases: ["gokyuzu", "gökyüzü", "gokyuzunde", "gökyüzünde"]),
                .init(label: "Bulut", aliases: ["bulut", "bulutlu"]),
                .init(label: "Sis", aliases: ["sis", "sisli"]),
                .init(label: "Şimşek", aliases: ["simsek", "şimşek", "yildirim", "yıldırım"])
            ]
        }
    }

    func matchedLabel(for normalizedToken: String) -> String? {
        for term in terms {
            for alias in term.aliases {
                let normalizedAlias = DreamObjectCategory.normalized(alias)
                if DreamObjectCategory.matches(token: normalizedToken, alias: normalizedAlias) {
                    return term.label
                }
            }
        }
        return nil
    }

    private static func normalized(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR"))
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func matches(token: String, alias: String) -> Bool {
        guard !token.isEmpty, !alias.isEmpty else { return false }
        if token == alias {
            return true
        }
        if token.contains(" ") || alias.contains(" ") {
            return false
        }
        if alias.count >= 4, token.hasPrefix(alias), token.count <= alias.count + 6 {
            return true
        }
        return false
    }
}

private struct DreamCategoryTerm {
    let label: String
    let aliases: [String]
}

private struct DreamEntityCount: Identifiable {
    let id = UUID()
    let label: String
    let count: Int
}

private struct DreamMonthPoint: Identifiable {
    let id = UUID()
    let label: String
    let value: Int
}

private struct DreamMoodShare: Identifiable {
    let id = UUID()
    let emoji: String
    let title: String
    let count: Int
}

struct DreamJournalHubView: View {
    @ObservedObject var viewModel: DreamInterpreterViewModel
    let onOpenInterpretation: (UUID) -> Void
    @Environment(\.usesSharedTabPanoramaBackground) private var usesSharedTabPanoramaBackground

    @State private var activeTab: DreamJournalTopTab = .dreams
    @State private var showFavoritesOnly = false
    @State private var searchText = ""
    @State private var isSearchExpanded = false
    @FocusState private var isSearchFocused: Bool

    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "tr_TR")
        cal.firstWeekday = 2
        return cal
    }

    private var orderedDreams: [DreamRecord] {
        viewModel.dreamRecords.sorted(by: { $0.createdAt > $1.createdAt })
    }

    private var baseDreams: [DreamRecord] {
        showFavoritesOnly ? orderedDreams.filter(\.isFavorite) : orderedDreams
    }

    private var visibleDreams: [DreamRecord] {
        let query = normalized(searchText)
        guard !query.isEmpty else { return baseDreams }
        return baseDreams.filter { record in
            searchableFields(for: record)
                .map(normalized)
                .contains(where: { $0.contains(query) })
        }
    }

    private var countBadgeText: String {
        let query = normalized(searchText)
        if activeTab == .dreams, !query.isEmpty {
            return "\(visibleDreams.count) sonuç"
        }
        return "\(orderedDreams.count) kayıt"
    }

    private var categoryBuckets: [DreamObjectCategory: [String: Int]] {
        var buckets: [DreamObjectCategory: [String: Int]] = [:]
        for category in DreamObjectCategory.allCases {
            buckets[category] = [:]
        }

        for record in orderedDreams {
            var seenInRecord = Set<String>()
            for token in tokenCandidates(for: record) {
                guard let match = categoryMatch(forToken: token) else { continue }
                let dedupeKey = "\(match.category.id)|\(match.label)"
                guard seenInRecord.insert(dedupeKey).inserted else { continue }
                buckets[match.category, default: [:]][match.label, default: 0] += 1
            }
        }

        return buckets
    }

    var body: some View {
        ZStack {
            if !usesSharedTabPanoramaBackground {
                DreamBackground()
            }

            ScrollView(showsIndicators: false) {
                VStack(spacing: DreamLayout.sectionSpacing) {
                    header
                    topTabs

                    if activeTab == .dreams {
                        dreamsSection
                    } else {
                        objectsSection
                    }

                    messages
                }
                .padding(.horizontal, DreamLayout.screenHorizontal)
                .padding(.top, DreamLayout.screenTop)
                .padding(.bottom, DreamLayout.screenBottom)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: activeTab) { _, newValue in
            guard newValue != .dreams else { return }
            closeSearch()
        }
    }

    private var header: some View {
        HStack {
            Text("Rüyalarım")
                .font(DreamTheme.heading(34))
                .foregroundStyle(Color.white)

            Spacer()

            Text(countBadgeText)
                .font(DreamTheme.medium(14))
                .foregroundStyle(Color.white.opacity(0.74))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.14))
                .clipShape(Capsule())
        }
    }

    private var topTabs: some View {
        HStack(spacing: 8) {
            ForEach(DreamJournalTopTab.allCases) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        activeTab = tab
                    }
                } label: {
                    Text(tab.rawValue)
                        .font(DreamTheme.medium(16))
                        .foregroundStyle(activeTab == tab ? DreamTheme.textDark : Color.white.opacity(0.84))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(activeTab == tab ? Color.white.opacity(0.90) : Color.black.opacity(0.20))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(activeTab == tab ? DreamTheme.goldEnd.opacity(0.55) : Color.white.opacity(0.12), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(5)
        .background(Color.white.opacity(0.09))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var dreamsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                filterPill(title: "Tümü", isActive: !showFavoritesOnly) {
                    showFavoritesOnly = false
                }
                filterPill(title: "Favoriler", isActive: showFavoritesOnly) {
                    showFavoritesOnly = true
                }

                Spacer()

                Button {
                    if isSearchExpanded {
                        closeSearch()
                    } else {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            isSearchExpanded = true
                        }
                        DispatchQueue.main.async {
                            isSearchFocused = true
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: isSearchExpanded ? "xmark.circle.fill" : "magnifyingglass")
                            .font(.system(size: 13, weight: .semibold))
                        Text(isSearchExpanded ? "Kapat" : "Ara")
                            .font(DreamTheme.medium(13.5))
                    }
                    .foregroundStyle(Color.white.opacity(0.90))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.black.opacity(0.22))
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.14), lineWidth: 1)
                    )
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            if isSearchExpanded {
                searchBar
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            if visibleDreams.isEmpty {
                VStack(spacing: 10) {
                    Text(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? (showFavoritesOnly ? "⭐" : "🌙") : "🔎")
                        .font(.system(size: 40))
                    Text(emptyDreamStateTitle)
                        .font(DreamTheme.medium(20))
                        .foregroundStyle(Color.white.opacity(0.88))
                    Text(emptyDreamStateSubtitle)
                        .font(DreamTheme.body(15))
                        .foregroundStyle(Color.white.opacity(0.68))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .dreamCard(light: false, cornerRadius: 20)
            } else {
                ForEach(visibleDreams) { record in
                    dreamRow(record)
                }
            }
        }
    }

    private func dreamRow(_ record: DreamRecord) -> some View {
        HStack(spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [DreamTheme.skyTop.opacity(0.98), DreamTheme.skyBottom.opacity(0.98)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text(emojiForMood(record.mood))
                    .font(.system(size: 19))
            }
            .frame(width: 42, height: 42)
            .padding(.leading, 10)
            .padding(.trailing, 10)

            VStack(alignment: .leading, spacing: 1) {
                Text(Self.cardDateFormatter.string(from: record.createdAt))
                    .font(DreamTheme.medium(13))
                    .foregroundStyle(DreamTheme.textDark.opacity(0.84))

                Text(record.displayTitle)
                    .font(DreamTheme.medium(14.5))
                    .foregroundStyle(DreamTheme.textDark)
                    .lineLimit(1)

                Text(record.previewSummary.isEmpty ? record.interpretation : record.previewSummary)
                    .font(DreamTheme.body(11))
                    .foregroundStyle(Color.black.opacity(0.48))
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            HStack(spacing: 5) {
                Button {
                    viewModel.toggleFavorite(recordID: record.id)
                } label: {
                    Image(systemName: record.isFavorite ? "star.fill" : "star")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(record.isFavorite ? DreamTheme.goldEnd : Color.black.opacity(0.34))
                        .frame(width: 18, height: 18)
                }
                .buttonStyle(.plain)

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.black.opacity(0.30))
            }
            .padding(.trailing, 8)
        }
        .padding(.vertical, 6)
        .frame(minHeight: 62)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(DreamTheme.cardLight)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.20), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.20), radius: 10, y: 4)
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onTapGesture {
            onOpenInterpretation(record.id)
        }
    }

    private var objectsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Rüya Nesneleri")
                    .font(DreamTheme.heading(33 * 0.86))
                    .foregroundStyle(Color.white)

                Text("Rüyalarındaki kişi, mekan, tema ve sembolleri keşfet")
                    .font(DreamTheme.body(16))
                    .foregroundStyle(Color.white.opacity(0.78))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(DreamObjectCategory.allCases) { category in
                NavigationLink {
                    DreamObjectAnalysisView(
                        category: category,
                        entities: categoryEntities(for: category),
                        monthlyTrend: monthlyTrend(records: categoryRecords(for: category), monthCount: 6),
                        moodDistribution: moodDistribution(records: categoryRecords(for: category))
                    )
                } label: {
                    objectCategoryRow(category)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func objectCategoryRow(_ category: DreamObjectCategory) -> some View {
        let total = (categoryBuckets[category] ?? [:]).count
        return HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(category.accent.opacity(0.30))
                Image(systemName: category.icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(category.accent)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 2) {
                Text(category.title)
                    .font(DreamTheme.medium(22 * 0.88))
                    .foregroundStyle(Color.white)
                Text("\(total) varlık")
                    .font(DreamTheme.body(16))
                    .foregroundStyle(Color.white.opacity(0.70))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.40))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.black.opacity(0.34))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.20), lineWidth: 1)
        )
    }

    private func filterPill(title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(DreamTheme.medium(14.5))
                .foregroundStyle(isActive ? DreamTheme.textDark : Color.white.opacity(0.82))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(isActive ? Color.white.opacity(0.88) : Color.black.opacity(0.20))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isActive ? DreamTheme.goldEnd.opacity(0.55) : Color.white.opacity(0.14), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.72))

            TextField("Rüya ara (başlık, içerik, tarih)", text: $searchText)
                .font(DreamTheme.body(14))
                .foregroundStyle(Color.white.opacity(0.92))
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .focused($isSearchFocused)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.white.opacity(0.56))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(Color.black.opacity(0.22))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func closeSearch() {
        withAnimation(.easeInOut(duration: 0.18)) {
            isSearchExpanded = false
            searchText = ""
        }
        isSearchFocused = false
    }

    private var emptyDreamStateTitle: String {
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Aramaya uygun rüya bulunamadı"
        }
        return showFavoritesOnly ? "Henüz favori rüya yok" : "Henüz kayıtlı rüya yok"
    }

    private var emptyDreamStateSubtitle: String {
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Başlık, içerik veya tarih için farklı bir kelime dene."
        }
        return "Yeni rüya kaydettikçe burada en güncelden eskiye sıralanacak."
    }

    @ViewBuilder
    private var messages: some View {
        if let info = viewModel.infoMessage {
            Text(info)
                .font(DreamTheme.medium(13))
                .foregroundStyle(Color.green.opacity(0.95))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        if let error = viewModel.errorMessage {
            Text(error)
                .font(DreamTheme.medium(13))
                .foregroundStyle(Color.red.opacity(0.95))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func categoryRecords(for targetCategory: DreamObjectCategory) -> [DreamRecord] {
        orderedDreams.filter { record in
            tokenCandidates(for: record)
                .contains(where: { categoryMatch(forToken: $0)?.category == targetCategory })
        }
    }

    private func categoryEntities(for category: DreamObjectCategory) -> [DreamEntityCount] {
        let values = categoryBuckets[category] ?? [:]
        return values
            .sorted { lhs, rhs in
                if lhs.value == rhs.value { return lhs.key < rhs.key }
                return lhs.value > rhs.value
            }
            .prefix(10)
            .map { DreamEntityCount(label: $0.key, count: $0.value) }
    }

    private func tokenCandidates(for record: DreamRecord) -> [String] {
        let symbolTokens = record.symbols
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let stopWords: Set<String> = [
            "ve", "ile", "ama", "fakat", "gibi", "icin", "için", "bir", "bu", "şu", "su", "o", "da", "de", "mi", "mu", "mü", "ben", "sen", "biz", "siz", "onlar", "çok", "cok", "daha", "kadar"
        ]

        let textTokens = record.dreamText
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count >= 3 && !stopWords.contains($0) }

        var output: [String] = []
        for token in (symbolTokens + textTokens) {
            if !output.contains(token) {
                output.append(token)
            }
            if output.count >= 36 {
                break
            }
        }

        return output
    }

    private func normalized(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR"))
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func searchableFields(for record: DreamRecord) -> [String] {
        [
            record.displayTitle,
            record.dreamText,
            record.previewSummary,
            record.interpretation,
            Self.cardDateFormatter.string(from: record.createdAt),
            Self.cardSlashDateFormatter.string(from: record.createdAt),
            Self.cardLongDateFormatter.string(from: record.createdAt),
            Self.cardWeekdayDateFormatter.string(from: record.createdAt)
        ]
    }

    private func categoryMatch(forToken token: String) -> (category: DreamObjectCategory, label: String)? {
        let normalizedToken = normalized(token)
        guard normalizedToken.count >= 2 else { return nil }
        for category in DreamObjectCategory.allCases {
            if let label = category.matchedLabel(for: normalizedToken) {
                return (category, label)
            }
        }
        return nil
    }

    private func monthlyTrend(records: [DreamRecord], monthCount: Int) -> [DreamMonthPoint] {
        let currentMonth = startOfMonth(for: Date())
        let monthStarts = (0..<monthCount).compactMap { offset in
            calendar.date(byAdding: .month, value: -(monthCount - 1 - offset), to: currentMonth)
        }

        return monthStarts.map { monthStart in
            guard let next = calendar.date(byAdding: .month, value: 1, to: monthStart) else {
                return DreamMonthPoint(label: Self.monthShortFormatter.string(from: monthStart), value: 0)
            }
            let count = records.filter { $0.createdAt >= monthStart && $0.createdAt < next }.count
            return DreamMonthPoint(label: Self.monthShortFormatter.string(from: monthStart).capitalized, value: count)
        }
    }

    private func moodDistribution(records: [DreamRecord]) -> [DreamMoodShare] {
        let mappings: [(title: String, emoji: String, matcher: (String) -> Bool)] = [
            ("Huzurlu", "😌", { text in text.contains("huzurlu") }),
            ("Harika", "😍", { text in text.contains("harika") }),
            ("Nötr", "😐", { text in text.contains("notr") || text.contains("nötr") }),
            ("Kafası Karışık", "🤔", { text in text.contains("kafasi") || text.contains("kafası") }),
            ("Kaygılı", "😰", { text in text.contains("kaygili") || text.contains("kaygılı") }),
            ("Korkunç", "😱", { text in text.contains("korkunc") || text.contains("korkunç") })
        ]

        return mappings.map { item in
            let count = records.reduce(0) { result, record in
                let mood = normalized(record.mood)
                return result + (item.matcher(mood) ? 1 : 0)
            }
            return DreamMoodShare(emoji: item.emoji, title: item.title, count: count)
        }
    }

    private func startOfMonth(for date: Date) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
    }

    private func emojiForMood(_ mood: String) -> String {
        let lower = mood.lowercased()
        if lower.contains("huzurlu") { return "😌" }
        if lower.contains("harika") { return "😍" }
        if lower.contains("kafası karışık") || lower.contains("kafasi karisik") { return "🤔" }
        if lower.contains("kaygılı") || lower.contains("kaygili") { return "😰" }
        if lower.contains("korkunç") || lower.contains("korkunc") { return "😱" }
        return "😐"
    }

    private static let cardDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter
    }()

    private static let cardSlashDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter
    }()

    private static let cardLongDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMMM yyyy"
        return formatter
    }()

    private static let cardWeekdayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "EEEE d MMMM yyyy"
        return formatter
    }()

    private static let monthShortFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "LLL"
        return formatter
    }()
}

private struct DreamObjectAnalysisView: View {
    let category: DreamObjectCategory
    let entities: [DreamEntityCount]
    let monthlyTrend: [DreamMonthPoint]
    let moodDistribution: [DreamMoodShare]

    @Environment(\.dismiss) private var dismiss
    @Environment(\.usesSharedTabPanoramaBackground) private var usesSharedTabPanoramaBackground

    var body: some View {
        ZStack {
            if !usesSharedTabPanoramaBackground {
                DreamBackground()
            }

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    topBar

                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(category.accent.opacity(0.18))
                            Image(systemName: category.icon)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(category.accent)
                        }
                        .frame(width: 56, height: 56)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(category.title) Analizleri")
                                .font(DreamTheme.heading(34 * 0.86))
                                .foregroundStyle(Color.white)
                            Text(category.subtitle)
                                .font(DreamTheme.body(16))
                                .foregroundStyle(Color.white.opacity(0.76))
                        }
                    }

                    DreamAnalyticsCard(
                        title: "Kategori Eğilimleri",
                        subtitle: "Son 6 aydaki görülme sıklığı",
                        icon: "chart.line.uptrend.xyaxis",
                        accent: category.accent
                    ) {
                        DreamMiniMonthChart(points: monthlyTrend, color: category.accent)
                    }

                    DreamAnalyticsCard(
                        title: "Ruh Hali Dağılımı",
                        subtitle: "Bu kategorideki rüyalarda duygusal profil",
                        icon: "face.smiling",
                        accent: category.accent
                    ) {
                        DreamMoodDistributionView(items: moodDistribution, accent: category.accent)
                    }

                    DreamAnalyticsCard(
                        title: "Nitelik Örüntüleri",
                        subtitle: "En sık geçen varlıklar",
                        icon: "circle.hexagongrid",
                        accent: category.accent
                    ) {
                        DreamEntityTagView(entities: entities, accent: category.accent)
                    }
                }
                .padding(.horizontal, DreamLayout.screenHorizontal)
                .padding(.top, DreamLayout.screenTop)
                .padding(.bottom, DreamLayout.screenBottom)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.96))
                    .frame(width: 34, height: 34)
                    .background(Color.black.opacity(0.20))
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.14), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)

            Spacer()
        }
    }
}

private struct DreamAnalyticsCard<Content: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    let accent: Color
    let content: Content

    init(
        title: String,
        subtitle: String,
        icon: String,
        accent: Color,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.accent = accent
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(accent.opacity(0.17))
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(accent)
                }
                .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(DreamTheme.medium(21 * 0.82))
                        .foregroundStyle(Color.white)
                    Text(subtitle)
                        .font(DreamTheme.body(14.5))
                        .foregroundStyle(Color.white.opacity(0.66))
                }

                Spacer()
            }

            content
        }
        .dreamCard(light: false, cornerRadius: 20)
    }
}

private struct DreamMiniMonthChart: View {
    let points: [DreamMonthPoint]
    let color: Color

    var body: some View {
        let maxValue = max(points.map(\.value).max() ?? 0, 1)

        return HStack(alignment: .bottom, spacing: 10) {
            ForEach(points) { point in
                VStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.94), color.opacity(0.45)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: CGFloat(point.value) / CGFloat(maxValue) * 84 + 8)

                    Text(point.label)
                        .font(DreamTheme.body(12.5))
                        .foregroundStyle(Color.white.opacity(0.72))
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 118)
        .padding(10)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct DreamMoodDistributionView: View {
    let items: [DreamMoodShare]
    let accent: Color

    var body: some View {
        let maxValue = max(items.map(\.count).max() ?? 0, 1)

        return VStack(spacing: 7) {
            ForEach(items) { item in
                HStack(spacing: 8) {
                    Text(item.emoji)
                        .font(.system(size: 15))

                    Text(item.title)
                        .font(DreamTheme.body(13.5))
                        .foregroundStyle(Color.white.opacity(0.86))
                        .frame(width: 108, alignment: .leading)

                    GeometryReader { geo in
                        let width = geo.size.width * CGFloat(item.count) / CGFloat(maxValue)
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color.white.opacity(0.08))
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(accent.opacity(item.count == 0 ? 0.22 : 0.88))
                                .frame(width: max(4, width))
                        }
                    }
                    .frame(height: 10)

                    Text("\(item.count)")
                        .font(DreamTheme.medium(12.5))
                        .foregroundStyle(Color.white.opacity(0.72))
                        .frame(width: 20, alignment: .trailing)
                }
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct DreamEntityTagView: View {
    let entities: [DreamEntityCount]
    let accent: Color

    var body: some View {
        if entities.isEmpty {
            Text("Bu kategoride henüz belirgin varlık bulunamadı.")
                .font(DreamTheme.body(14.5))
                .foregroundStyle(Color.white.opacity(0.68))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        } else {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(entities.prefix(6)) { entity in
                    HStack(spacing: 8) {
                        Text(entity.label)
                            .font(DreamTheme.body(14.5))
                            .foregroundStyle(Color.white.opacity(0.92))
                            .lineLimit(1)

                        Spacer(minLength: 8)

                        Text("\(entity.count)x")
                            .font(DreamTheme.medium(12.5))
                            .foregroundStyle(accent.opacity(0.95))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(accent.opacity(0.16))
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(10)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}
