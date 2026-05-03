import SwiftUI
import WidgetKit

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> StreakEntry {
        StreakEntry.placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (StreakEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StreakEntry>) -> Void) {
        let entry = currentEntry()
        let nextUpdate = Calendar.current.nextDate(
            after: entry.date,
            matching: DateComponents(hour: 0, minute: 5),
            matchingPolicy: .nextTime
        ) ?? entry.date.addingTimeInterval(60 * 60 * 6)

        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func currentEntry() -> StreakEntry {
        guard let data = WidgetDataStore.readStreak() else {
            return .placeholder
        }
        let week = normalizeWeekDays(data.weekDays)
        let calendarWeek = normalizeCalendarWeek(data.calendarWeek, fallbackFive: data.weekDays)
        return StreakEntry(
            date: .now,
            currentStreak: data.currentStreak,
            longestStreak: data.longestStreak,
            totalCompletedDays: data.totalCompletedDays,
            week: week,
            calendarWeek: calendarWeek
        )
    }

    /// App sends exactly five rolling days; pad or trim defensively for older payloads.
    private func normalizeWeekDays(_ days: [SharedWeekDay]) -> [WeekdayStatus] {
        var mapped = days.map { WeekdayStatus(symbol: $0.symbol, isCompleted: $0.isCompleted) }
        if mapped.count > 5 {
            mapped = Array(mapped.prefix(5))
        }
        while mapped.count < 5 {
            mapped.append(WeekdayStatus(symbol: "·", isCompleted: false))
        }
        return mapped
    }

    /// Seven-day strip for the large widget (matches share card). Falls back if app hasn’t written `calendarWeek` yet.
    private func normalizeCalendarWeek(_ days: [SharedWeekDay]?, fallbackFive: [SharedWeekDay]) -> [WeekdayStatus] {
        if let days, days.count >= 7 {
            return Array(days.prefix(7)).map { WeekdayStatus(symbol: $0.symbol, isCompleted: $0.isCompleted) }
        }
        if let days, !days.isEmpty {
            var mapped = days.map { WeekdayStatus(symbol: $0.symbol, isCompleted: $0.isCompleted) }
            while mapped.count < 7 {
                mapped.append(WeekdayStatus(symbol: "·", isCompleted: false))
            }
            return Array(mapped.prefix(7))
        }
        let fb = normalizeWeekDays(fallbackFive)
        var out: [WeekdayStatus] = fb
        while out.count < 7 {
            out.append(WeekdayStatus(symbol: "·", isCompleted: false))
        }
        return Array(out.prefix(7))
    }
}

struct StreakEntry: TimelineEntry {
    let date: Date
    let currentStreak: Int
    let longestStreak: Int
    let totalCompletedDays: Int
    /// Five rolling days (medium widget).
    let week: [WeekdayStatus]
    /// Seven weekday strip (large widget).
    let calendarWeek: [WeekdayStatus]

    static let placeholder = StreakEntry(
        date: .now,
        currentStreak: 3,
        longestStreak: 8,
        totalCompletedDays: 12,
        week: [
            WeekdayStatus(symbol: "13", isCompleted: true),
            WeekdayStatus(symbol: "14", isCompleted: true),
            WeekdayStatus(symbol: "15", isCompleted: false),
            WeekdayStatus(symbol: "16", isCompleted: false),
            WeekdayStatus(symbol: "17", isCompleted: false)
        ],
        calendarWeek: [
            WeekdayStatus(symbol: "S", isCompleted: true),
            WeekdayStatus(symbol: "M", isCompleted: true),
            WeekdayStatus(symbol: "T", isCompleted: false),
            WeekdayStatus(symbol: "W", isCompleted: false),
            WeekdayStatus(symbol: "T", isCompleted: false),
            WeekdayStatus(symbol: "F", isCompleted: false),
            WeekdayStatus(symbol: "S", isCompleted: false)
        ]
    )
}

struct WeekdayStatus: Equatable {
    let symbol: String
    let isCompleted: Bool
}

struct StreakWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: Provider.Entry

    var body: some View {
        content
            .padding(padding)
            .containerBackground(for: .widget) {
                if family == .systemLarge {
                    WidgetPalette.canvasBackground
                } else {
                    WidgetPalette.canvasSolid
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .systemLarge:
            largeShareStyleWidget
        default:
            mediumWidget
        }
    }

    private var padding: CGFloat {
        switch family {
        case .systemLarge: 10
        default: 14
        }
    }

    private var mediumWidget: some View {
        HStack(alignment: .center, spacing: 4) {
            VStack(alignment: .leading, spacing: 0) {
                streakHeaderMedium
                    .padding(.bottom, 10)

                streakDivider
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 12)

                weekDotsRow(days: entry.week, circleSize: 28, textSize: 11, spacing: 5, shareStyleIncomplete: false)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            streakHeroImage
                .frame(maxWidth: 120, maxHeight: .infinity)
                .padding(.trailing, -6)
                .padding(.vertical, -4)
        }
    }

    private var largeShareStyleWidget: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let heroD = min(w * 0.46, h * 0.30)
            let heroNum = heroD * 0.36
            let captionSize = max(9, heroD * 0.082)
            let headline = max(13, w * 0.038)
            let brandLine = max(11, w * 0.03)
            let statValue = max(20, w * 0.072)
            let statLabel = max(10, w * 0.03)
            let weekDot = max(22, min(w * 0.11, 34))
            let weekLbl = max(9, w * 0.028)
            let cardCorner: CGFloat = 14

            VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    VStack(spacing: 5) {
                        HStack(spacing: 7) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: headline * 0.72, weight: .semibold))
                                .foregroundStyle(WidgetPalette.accent)
                            Text("Streak unlocked")
                                .font(.system(size: headline, weight: .bold, design: .rounded))
                                .foregroundStyle(WidgetPalette.primaryText)
                                .minimumScaleFactor(0.75)
                                .lineLimit(1)
                        }
                        Text("Bible Life")
                            .font(.system(size: brandLine, weight: .semibold, design: .serif))
                            .foregroundStyle(WidgetPalette.secondaryText)
                    }
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 2)
                    .padding(.bottom, 8)

                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [WidgetPalette.accent, WidgetPalette.headerAccent.opacity(0.92)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: heroD, height: heroD)
                            .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)

                        VStack(spacing: heroD * 0.04) {
                            Text("\(entry.currentStreak)")
                                .font(.system(size: heroNum, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .minimumScaleFactor(0.35)
                                .lineLimit(1)
                            Text(entry.currentStreak == 1 ? "DAY STREAK" : "DAYS STREAK")
                                .font(.system(size: captionSize, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.95))
                                .tracking(1.5)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)

                    HStack(alignment: .top, spacing: 9) {
                        largeStatCard(title: "Longest", value: "\(entry.longestStreak)", statLabel: statLabel, statValue: statValue, corner: cardCorner)
                        largeStatCard(title: "Total days", value: "\(entry.totalCompletedDays)", statLabel: statLabel, statValue: statValue, corner: cardCorner)
                    }
                    .padding(.top, 8)

                    VStack(spacing: 7) {
                        Text("THIS WEEK")
                            .font(.system(size: max(10, w * 0.03), weight: .bold, design: .rounded))
                            .foregroundStyle(WidgetPalette.primaryText)
                            .tracking(0.8)

                        weekDotsRow(days: entry.calendarWeek, circleSize: weekDot, textSize: weekLbl, spacing: 0, shareStyleIncomplete: true)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 10)

                    Text("Consistency is worship")
                        .font(.system(size: max(9, w * 0.027), weight: .semibold, design: .serif))
                        .foregroundStyle(WidgetPalette.primaryText.opacity(0.88))
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                        .padding(.bottom, 4)

                    Text("Bible Life · Live the Word")
                        .font(.system(size: max(8, w * 0.024), weight: .medium, design: .rounded))
                        .foregroundStyle(WidgetPalette.secondaryText.opacity(0.95))
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 6)
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func largeStatCard(title: String, value: String, statLabel: CGFloat, statValue: CGFloat, corner: CGFloat) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: statLabel, weight: .medium, design: .rounded))
                .foregroundStyle(WidgetPalette.secondaryText)
            Text(value)
                .font(.system(size: statValue, weight: .bold, design: .rounded))
                .foregroundStyle(WidgetPalette.primaryText)
                .minimumScaleFactor(0.45)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 11)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(WidgetPalette.cardFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .stroke(WidgetPalette.border.opacity(0.55), lineWidth: 1)
        )
    }

    private var streakHeaderMedium: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            flameBadge(size: 40, flameSize: 17)

            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text("\(entry.currentStreak)")
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                    .foregroundStyle(WidgetPalette.primaryText)
                Text("days")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(WidgetPalette.secondaryText)
            }
        }
    }

    private func flameBadge(size: CGFloat, flameSize: CGFloat) -> some View {
        Circle()
            .fill(WidgetPalette.headerAccent.opacity(0.92))
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: "flame.fill")
                    .font(.system(size: flameSize, weight: .semibold))
                    .foregroundStyle(.white)
            }
    }

    private var streakDivider: some View {
        GeometryReader { geo in
            Rectangle()
                .fill(WidgetPalette.border.opacity(0.55))
                .frame(width: min(geo.size.width * 0.92, 200), height: 1)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 1)
    }

    private var streakHeroImage: some View {
        Image("StreakHero")
            .resizable()
            .scaledToFit()
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .accessibilityHidden(true)
    }

    private func weekDotsRow(
        days: [WeekdayStatus],
        circleSize: CGFloat,
        textSize: CGFloat,
        spacing: CGFloat,
        shareStyleIncomplete: Bool
    ) -> some View {
        HStack(spacing: spacing) {
            ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                weekdayDot(day, circleSize: circleSize, textSize: textSize, shareStyleIncomplete: shareStyleIncomplete)
            }
        }
    }

    private func weekdayDot(
        _ day: WeekdayStatus,
        circleSize: CGFloat,
        textSize: CGFloat,
        shareStyleIncomplete: Bool
    ) -> some View {
        let strokeW: CGFloat = day.isCompleted ? 0 : max(1.5, circleSize * 0.07)
        return VStack(spacing: shareStyleIncomplete ? 4 : 5) {
            ZStack {
                if day.isCompleted {
                    Circle()
                        .fill(WidgetPalette.accent)
                        .frame(width: circleSize, height: circleSize)
                        .overlay {
                            Circle()
                                .stroke(WidgetPalette.accent.opacity(0.35), lineWidth: 1)
                        }
                        .overlay {
                            Image(systemName: "checkmark")
                                .font(.system(size: circleSize * 0.4, weight: .bold))
                                .foregroundStyle(.white)
                        }
                } else if shareStyleIncomplete {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: circleSize, height: circleSize)
                        .overlay {
                            Circle()
                                .stroke(WidgetPalette.accent.opacity(0.85), lineWidth: strokeW)
                        }
                } else {
                    Circle()
                        .fill(WidgetPalette.pendingFill)
                        .frame(width: circleSize, height: circleSize)
                        .overlay {
                            Circle()
                                .stroke(WidgetPalette.pendingStroke, lineWidth: 1)
                        }
                }
            }

            Text(day.symbol)
                .font(.system(size: textSize, weight: shareStyleIncomplete ? .bold : .semibold, design: .rounded))
                .foregroundStyle(shareStyleIncomplete ? WidgetPalette.primaryText : WidgetPalette.secondaryText)
                .minimumScaleFactor(0.55)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

struct StreakWidget: Widget {
    let kind: String = "StreakWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            StreakWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Bible Streak")
        .description("Medium: streak and five rolling days. Large: full streak story with week, stats, and hero.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

private enum WidgetPalette {
    /// Medium widget: unchanged flat canvas.
    static let canvasSolid = Color(red: 0.98, green: 0.97, blue: 0.94)
    static let canvasTop = Color(red: 0.98, green: 0.97, blue: 0.94)
    static let canvasBottom = Color(red: 0.94, green: 0.96, blue: 0.91)
    static let canvasBackground = LinearGradient(
        colors: [canvasTop, canvasBottom],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let cardFill = Color(red: 0.99, green: 0.98, blue: 0.96)
    static let headerAccent = Color(red: 0.68, green: 0.73, blue: 0.62)
    static let accent = Color(red: 0.70, green: 0.77, blue: 0.63)
    static let pendingFill = Color(red: 0.95, green: 0.93, blue: 0.89)
    static let pendingStroke = Color(red: 0.89, green: 0.86, blue: 0.80)
    static let primaryText = Color(red: 0.34, green: 0.30, blue: 0.24)
    static let secondaryText = Color(red: 0.50, green: 0.47, blue: 0.41)
    static let border = Color(red: 0.87, green: 0.84, blue: 0.77)
}

#Preview(as: .systemMedium) {
    StreakWidget()
} timeline: {
    StreakEntry.placeholder
}
#Preview(as: .systemLarge) {
    StreakWidget()
} timeline: {
    StreakEntry.placeholder
}
