import SwiftUI

private enum DreamMoodFilter: String, CaseIterable, Identifiable {
    case all
    case peaceful
    case great
    case neutral
    case confused
    case anxious
    case scary

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return String(localized: "calendar.filter.all")
        case .peaceful: return String(localized: "calendar.filter.peaceful")
        case .great: return String(localized: "calendar.filter.great")
        case .neutral: return String(localized: "calendar.filter.neutral")
        case .confused: return String(localized: "calendar.filter.confused")
        case .anxious: return String(localized: "calendar.filter.anxious")
        case .scary: return String(localized: "calendar.filter.scary")
        }
    }

    var emoji: String {
        switch self {
        case .all: return "✨"
        case .peaceful: return "😌"
        case .great: return "😍"
        case .neutral: return "😐"
        case .confused: return "🤔"
        case .anxious: return "😰"
        case .scary: return "😱"
        }
    }

    func matches(mood: String) -> Bool {
        let detected = DreamMoodKind.detect(from: mood)
        switch self {
        case .all:
            return true
        case .peaceful:
            return detected == .peaceful
        case .great:
            return detected == .great
        case .neutral:
            return detected == .neutral
        case .confused:
            return detected == .confused
        case .anxious:
            return detected == .anxious
        case .scary:
            return detected == .scary
        }
    }
}

private struct DreamDayCell: Identifiable {
    let id: String
    let date: Date?
}

struct DreamCalendarView: View {
    @ObservedObject var viewModel: DreamInterpreterViewModel
    let onOpenInterpretation: (UUID) -> Void
    @Environment(\.usesSharedTabPanoramaBackground) private var usesSharedTabPanoramaBackground

    @State private var selectedDate = Date()
    @State private var activeFilter: DreamMoodFilter = .all
    @State private var hasExplicitDaySelection = false
    @State private var hasInitialMonthScroll = false
    @State private var todayScrollRequest = 0

    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = .autoupdatingCurrent
        return cal
    }

    private var filteredRecords: [DreamRecord] {
        viewModel.dreamRecords.filter { activeFilter.matches(mood: $0.mood) }
    }

    private var selectedDayRecords: [DreamRecord] {
        filteredRecords
            .filter { calendar.isDate($0.createdAt, inSameDayAs: selectedDate) }
            .sorted(by: { $0.createdAt > $1.createdAt })
    }

    private var monthsToDisplay: [Date] {
        let todayMonth = startOfMonth(for: Date())
        let selectedMonth = startOfMonth(for: selectedDate)
        let recordMonths = filteredRecords.map { startOfMonth(for: $0.createdAt) }

        var start = calendar.date(byAdding: .month, value: -120, to: todayMonth) ?? todayMonth
        var end = calendar.date(byAdding: .month, value: 120, to: todayMonth) ?? todayMonth

        let selectedStart = calendar.date(byAdding: .month, value: -24, to: selectedMonth) ?? selectedMonth
        let selectedEnd = calendar.date(byAdding: .month, value: 24, to: selectedMonth) ?? selectedMonth
        start = min(start, selectedStart)
        end = max(end, selectedEnd)

        if let minRecordMonth = recordMonths.min() {
            let candidate = calendar.date(byAdding: .month, value: -24, to: minRecordMonth) ?? minRecordMonth
            start = min(start, candidate)
        }
        if let maxRecordMonth = recordMonths.max() {
            let candidate = calendar.date(byAdding: .month, value: 24, to: maxRecordMonth) ?? maxRecordMonth
            end = max(end, candidate)
        }

        return monthRange(from: start, to: end)
    }

    private var currentMonthRecords: [DreamRecord] {
        let start = startOfMonth(for: selectedDate)
        guard let end = calendar.date(byAdding: .month, value: 1, to: start) else { return [] }
        return filteredRecords.filter { $0.createdAt >= start && $0.createdAt < end }
    }

    private var shouldShowPopupPanel: Bool {
        hasExplicitDaySelection
    }

    var body: some View {
        ZStack {
            if !usesSharedTabPanoramaBackground {
                DreamBackground()
            }

            VStack(spacing: DreamLayout.sectionSpacing) {
                topBar

                VStack(spacing: 12) {
                    filterBar
                    weekdayHeader

                    ScrollViewReader { proxy in
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 0) {
                                LazyVStack(spacing: 22) {
                                    ForEach(monthsToDisplay, id: \.self) { month in
                                        monthSection(month: month)
                                            .id(month)
                                    }
                                }
                                .padding(.top, 6)

                                monthStatsPanel
                                    .padding(.top, 22)
                            }
                            .padding(.bottom, 24)
                        }
                        .frame(maxHeight: .infinity)
                        .onAppear {
                            guard !hasInitialMonthScroll else { return }
                            hasInitialMonthScroll = true
                            scrollToMonth(startOfMonth(for: selectedDate), using: proxy, animated: false)
                        }
                        .onChange(of: todayScrollRequest) { _, _ in
                            let target = selectedDate
                            scrollToMonth(startOfMonth(for: target), using: proxy, animated: true)

                            // Ay bölümü lazy olarak oluştuğunda gün hücresine ikinci adımda odaklan.
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                                scrollToDay(target, using: proxy, animated: true)
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                                scrollToDay(target, using: proxy, animated: true)
                            }
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 12)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .background(calendarPanelBackground)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.horizontal, DreamLayout.screenHorizontal)
            .padding(.top, DreamLayout.screenTop)
        }
        .overlay(alignment: .bottom) {
            if shouldShowPopupPanel {
                selectedDayPanel
                    .padding(.horizontal, DreamLayout.screenHorizontal)
                    .padding(.bottom, 82)
                    .background(Color.clear)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(20)
            }
        }
        .animation(.interactiveSpring(response: 0.42, dampingFraction: 0.88, blendDuration: 0.16), value: shouldShowPopupPanel)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var calendarPanelBackground: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.17, green: 0.20, blue: 0.45).opacity(usesSharedTabPanoramaBackground ? 0.88 : 0.82),
                        Color(red: 0.18, green: 0.21, blue: 0.48).opacity(usesSharedTabPanoramaBackground ? 0.80 : 0.74)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.24), lineWidth: 1)
            )
    }

    private var topBar: some View {
        HStack {
            Text(String(localized: "calendar.title"))
                .font(DreamTheme.heading(34))
                .foregroundStyle(Color.white)

            Spacer()
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(DreamMoodFilter.allCases) { filter in
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            activeFilter = filter
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text(filter.emoji)
                            Text(filter.title)
                        }
                        .font(DreamTheme.medium(16))
                        .foregroundStyle(activeFilter == filter ? DreamTheme.goldStart : Color.white.opacity(0.82))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(
                                    activeFilter == filter
                                    ? Color.white.opacity(0.14)
                                    : Color.black.opacity(usesSharedTabPanoramaBackground ? 0.34 : 0.20)
                                )
                        )
                        .overlay(
                            Capsule()
                                .stroke(
                                    activeFilter == filter ? DreamTheme.goldEnd.opacity(0.9) : Color.white.opacity(0.15),
                                    lineWidth: activeFilter == filter ? 1.2 : 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var weekdayHeader: some View {
        let rawSymbols = calendar.veryShortStandaloneWeekdaySymbols
        let firstIndex = max(0, min(calendar.firstWeekday - 1, rawSymbols.count - 1))
        let symbols = Array(rawSymbols[firstIndex...]) + Array(rawSymbols[..<firstIndex])

        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 0) {
            ForEach(Array(symbols.enumerated()), id: \.offset) { _, symbol in
                Text(symbol)
                    .font(DreamTheme.medium(15))
                    .foregroundStyle(Color.white.opacity(0.42))
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 8)
        .background(Color.black.opacity(usesSharedTabPanoramaBackground ? 0.28 : 0.18))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func monthSection(month: Date) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(Self.monthFormatter.string(from: month).capitalized)
                .font(DreamTheme.heading(42 * 0.63))
                .foregroundStyle(Color.white.opacity(0.92))

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 10) {
                ForEach(dayCells(for: month)) { cell in
                    dayCellView(cell)
                        .id(cell.id)
                }
            }
        }
    }

    @ViewBuilder
    private func dayCellView(_ cell: DreamDayCell) -> some View {
        if let date = cell.date {
            let day = calendar.component(.day, from: date)
            let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
            let hasDream = !records(on: date).isEmpty

            Button {
                selectedDate = date
                hasExplicitDaySelection = true
            } label: {
                VStack(spacing: 4) {
                    Text("\(day)")
                        .font(DreamTheme.medium(35 * 0.59))
                        .foregroundStyle(
                            isSelected
                            ? DreamTheme.textDark
                            : (
                                hasDream
                                ? Color.white.opacity(usesSharedTabPanoramaBackground ? 0.96 : 0.88)
                                : Color.white.opacity(usesSharedTabPanoramaBackground ? 0.54 : 0.32)
                            )
                        )

                    Circle()
                        .fill(isSelected ? DreamTheme.textDark.opacity(0.72) : DreamTheme.goldStart.opacity(hasDream ? 0.95 : 0.0))
                        .frame(width: 5, height: 5)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            isSelected
                            ? LinearGradient(
                                colors: [DreamTheme.goldStart, DreamTheme.goldEnd],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(colors: [Color.clear, Color.clear], startPoint: .top, endPoint: .bottom)
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(isSelected ? DreamTheme.goldStart.opacity(0.0) : Color.white.opacity(0.06), lineWidth: 1)
                )
                .shadow(color: isSelected ? DreamTheme.goldEnd.opacity(0.35) : .clear, radius: 16, y: 6)
            }
            .buttonStyle(.plain)
        } else {
            Color.clear
                .frame(height: 56)
        }
    }

    private var selectedDayPanel: some View {
        VStack(spacing: 10) {
            HStack(alignment: .center) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 44, height: 44)
                    Text("🌙")
                        .font(.system(size: 22))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(Self.selectedDateFormatter.string(from: selectedDate).capitalized)
                        .font(DreamTheme.medium(40 * 0.60))
                        .foregroundStyle(Color.white)

                    Text(selectedDayStatusText)
                        .font(DreamTheme.body(16))
                        .foregroundStyle(Color.white.opacity(0.72))
                }

                Spacer()

                Button {
                    let today = Date()
                    selectedDate = today
                    todayScrollRequest += 1
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.system(size: 14, weight: .semibold))
                        Text(String(localized: "calendar.today"))
                            .font(DreamTheme.medium(16))
                    }
                    .foregroundStyle(DreamTheme.goldStart)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.24))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(DreamTheme.goldEnd.opacity(0.65), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }

            Divider().background(Color.white.opacity(0.12))

            if selectedDayRecords.isEmpty {
                VStack(spacing: 6) {
                    Text("🌙")
                        .font(.system(size: 36))
                    Text(String(localized: "calendar.empty.none_today"))
                        .font(DreamTheme.medium(34 * 0.54))
                        .foregroundStyle(Color.white.opacity(0.85))
                    Text(String(localized: "calendar.empty.tap_date"))
                        .font(DreamTheme.body(14))
                        .foregroundStyle(Color.white.opacity(0.52))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            } else {
                VStack(spacing: 10) {
                    ForEach(selectedDayRecords.prefix(2)) { record in
                        Button {
                            onOpenInterpretation(record.id)
                        } label: {
                            HStack(spacing: 10) {
                                Text(emojiForMood(record.mood))
                                    .font(.system(size: 26))

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(record.displayTitle)
                                        .font(DreamTheme.medium(18))
                                        .foregroundStyle(Color.white)
                                        .lineLimit(1)

                                    Text(record.previewSummary.isEmpty ? record.interpretation : record.previewSummary)
                                        .font(DreamTheme.body(14))
                                        .foregroundStyle(Color.white.opacity(0.72))
                                        .lineLimit(2)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Color.white.opacity(0.45))
                            }
                            .padding(12)
                            .background(Color.white.opacity(0.07))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .dreamCard(light: false, cornerRadius: 24)
        .shadow(color: .black.opacity(0.30), radius: 20, y: 12)
    }

    private var monthStatsPanel: some View {
        VStack(spacing: 10) {
            Text("📊")
                .font(.system(size: 36))
            Text(monthStatsTitle)
                .font(DreamTheme.medium(36 * 0.54))
                .foregroundStyle(Color.white.opacity(0.80))
                .multilineTextAlignment(.center)
            Text(monthStatsSubtitle)
                .font(DreamTheme.body(15))
                .foregroundStyle(Color.white.opacity(0.58))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .dreamCard(light: false, cornerRadius: 24)
    }

    private var monthStatsTitle: String {
        let monthTitle = Self.monthFormatter.string(from: startOfMonth(for: selectedDate)).capitalized
        if currentMonthRecords.isEmpty {
            return String(
                format: String(localized: "calendar.stats.empty_month_format"),
                locale: .autoupdatingCurrent,
                monthTitle
            )
        }
        return String(
            format: String(localized: "calendar.stats.month_count_format"),
            locale: .autoupdatingCurrent,
            monthTitle,
            currentMonthRecords.count
        )
    }

    private var monthStatsSubtitle: String {
        guard !currentMonthRecords.isEmpty else {
            return String(localized: "calendar.stats.empty_subtitle")
        }

        let grouped = Dictionary(grouping: currentMonthRecords, by: { $0.mood })
        let topMood = grouped.max(by: { $0.value.count < $1.value.count })?.key ?? defaultDreamMoodLabel()
        return String(
            format: String(localized: "calendar.stats.top_mood_format"),
            locale: .autoupdatingCurrent,
            localizedMoodLabel(for: topMood)
        )
    }

    private var selectedDayStatusText: String {
        if selectedDayRecords.isEmpty {
            return String(localized: "calendar.day.none")
        }
        return String(
            format: String(localized: "calendar.day.count_format"),
            locale: .autoupdatingCurrent,
            selectedDayRecords.count
        )
    }

    private func dayCells(for month: Date) -> [DreamDayCell] {
        guard let dayRange = calendar.range(of: .day, in: .month, for: month) else { return [] }

        let firstWeekday = calendar.component(.weekday, from: month)
        let leadingSpaces = (firstWeekday - calendar.firstWeekday + 7) % 7

        let monthStart = startOfMonth(for: month)
        let monthStamp = Int(monthStart.timeIntervalSinceReferenceDate)

        var cells: [DreamDayCell] = []
        for offset in 0..<leadingSpaces {
            cells.append(DreamDayCell(id: "m\(monthStamp)-lead-\(offset)", date: nil))
        }

        for day in dayRange {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: month) {
                let dayStamp = Int(calendar.startOfDay(for: date).timeIntervalSinceReferenceDate)
                cells.append(DreamDayCell(id: "m\(monthStamp)-day-\(dayStamp)", date: date))
            }
        }

        let trailingSpaces = (7 - (cells.count % 7)) % 7
        for offset in 0..<trailingSpaces {
            cells.append(DreamDayCell(id: "m\(monthStamp)-trail-\(offset)", date: nil))
        }

        return cells
    }

    private func records(on date: Date) -> [DreamRecord] {
        filteredRecords.filter { calendar.isDate($0.createdAt, inSameDayAs: date) }
    }

    private func startOfMonth(for date: Date) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
    }

    private func monthRange(from start: Date, to end: Date) -> [Date] {
        let first = startOfMonth(for: start)
        let last = startOfMonth(for: end)
        guard first <= last else { return [] }

        var months: [Date] = []
        var cursor = first

        while cursor <= last {
            months.append(cursor)
            guard let next = calendar.date(byAdding: .month, value: 1, to: cursor) else {
                break
            }
            cursor = next
        }
        return months
    }

    private func dayCellID(for date: Date) -> String {
        let monthStart = startOfMonth(for: date)
        let monthStamp = Int(monthStart.timeIntervalSinceReferenceDate)
        let dayStamp = Int(calendar.startOfDay(for: date).timeIntervalSinceReferenceDate)
        return "m\(monthStamp)-day-\(dayStamp)"
    }

    private func scrollToDay(
        _ date: Date,
        using proxy: ScrollViewProxy,
        animated: Bool
    ) {
        let action = {
            proxy.scrollTo(dayCellID(for: date), anchor: .center)
        }
        if animated {
            withAnimation(.easeInOut(duration: 0.25)) {
                action()
            }
        } else {
            action()
        }
    }

    private func scrollToMonth(
        _ month: Date,
        using proxy: ScrollViewProxy,
        animated: Bool
    ) {
        let action = {
            proxy.scrollTo(month, anchor: .top)
        }
        if animated {
            withAnimation(.easeInOut(duration: 0.25)) {
                action()
            }
        } else {
            action()
        }
    }

    private func emojiForMood(_ mood: String) -> String {
        moodEmoji(for: mood)
    }

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.setLocalizedDateFormatFromTemplate("LLLL yyyy")
        return formatter
    }()

    private static let selectedDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.setLocalizedDateFormatFromTemplate("d MMMM EEEE")
        return formatter
    }()
}
