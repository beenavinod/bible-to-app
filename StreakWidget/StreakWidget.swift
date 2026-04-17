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
        return StreakEntry(
            date: .now,
            currentStreak: data.currentStreak,
            longestStreak: data.longestStreak,
            totalCompletedDays: data.totalCompletedDays,
            week: week
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
}

struct StreakEntry: TimelineEntry {
    let date: Date
    let currentStreak: Int
    let longestStreak: Int
    let totalCompletedDays: Int
    let week: [WeekdayStatus]

    static let placeholder = StreakEntry(
        date: .now,
        currentStreak: 3,
        longestStreak: 0,
        totalCompletedDays: 12,
        week: [
            WeekdayStatus(symbol: "13", isCompleted: true),
            WeekdayStatus(symbol: "14", isCompleted: true),
            WeekdayStatus(symbol: "15", isCompleted: false),
            WeekdayStatus(symbol: "16", isCompleted: false),
            WeekdayStatus(symbol: "17", isCompleted: false)
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
                WidgetPalette.canvasSolid
            }
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .systemLarge:
            largeWidget
        default:
            mediumWidget
        }
    }

    private var padding: CGFloat {
        switch family {
        case .systemLarge: 18
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

                weekDotsRow(circleSize: 28, textSize: 11, spacing: 5)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            streakHeroImage
                .frame(maxWidth: 120, maxHeight: .infinity)
                .padding(.trailing, -6)
                .padding(.vertical, -4)
        }
    }

    private var largeWidget: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 6) {
                VStack(alignment: .leading, spacing: 0) {
                    streakHeaderLarge
                        .padding(.bottom, 12)

                    streakDivider
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 14)

                    weekDotsRow(circleSize: 34, textSize: 12, spacing: 7)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                streakHeroImage
                    .frame(maxWidth: 140, maxHeight: 168)
                    .padding(.trailing, -8)
            }

            totalDaysCard
        }
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

    private var streakHeaderLarge: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            flameBadge(size: 48, flameSize: 20)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(entry.currentStreak)")
                    .font(.system(size: 38, weight: .semibold, design: .rounded))
                    .foregroundStyle(WidgetPalette.primaryText)
                Text("days")
                    .font(.system(size: 16, weight: .medium))
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

    private func weekDotsRow(circleSize: CGFloat, textSize: CGFloat, spacing: CGFloat) -> some View {
        HStack(spacing: spacing) {
            ForEach(Array(entry.week.enumerated()), id: \.offset) { _, day in
                weekdayDot(day, circleSize: circleSize, textSize: textSize)
            }
        }
    }

    private var totalDaysCard: some View {
        VStack(spacing: 4) {
            Text("Total Days Completed")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(WidgetPalette.secondaryText)
            Text("\(entry.totalCompletedDays)")
                .font(.system(size: 30, weight: .semibold, design: .rounded))
                .foregroundStyle(WidgetPalette.primaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(WidgetPalette.cardFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(WidgetPalette.border.opacity(0.65), lineWidth: 1)
        )
    }

    private func weekdayDot(_ day: WeekdayStatus, circleSize: CGFloat, textSize: CGFloat) -> some View {
        VStack(spacing: 5) {
            Circle()
                .fill(day.isCompleted ? WidgetPalette.accent : WidgetPalette.pendingFill)
                .frame(width: circleSize, height: circleSize)
                .overlay {
                    Circle()
                        .stroke(
                            day.isCompleted ? WidgetPalette.accent.opacity(0.35) : WidgetPalette.pendingStroke,
                            lineWidth: 1
                        )
                }
                .overlay {
                    if day.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: circleSize * 0.4, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }

            Text(day.symbol)
                .font(.system(size: textSize, weight: .semibold))
                .foregroundStyle(WidgetPalette.secondaryText)
                .minimumScaleFactor(0.65)
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
        .description("Shows your streak, total completed days, and the latest five calendar days (by date).")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

private enum WidgetPalette {
    static let canvasSolid = Color(red: 0.98, green: 0.97, blue: 0.94)
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
