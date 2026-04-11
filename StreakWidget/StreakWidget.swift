//
//  StreakWidget.swift
//  StreakWidget
//
//  Created by Beena Vinod on 11/04/26.
//

import SwiftUI
import WidgetKit

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> StreakEntry {
        StreakEntry.placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (StreakEntry) -> Void) {
        completion(.placeholder)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StreakEntry>) -> Void) {
        let entry = StreakEntry.placeholder
        let nextUpdate = Calendar.current.nextDate(
            after: entry.date,
            matching: DateComponents(hour: 0, minute: 5),
            matchingPolicy: .nextTime
        ) ?? entry.date.addingTimeInterval(60 * 60 * 6)

        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
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
        currentStreak: 6,
        longestStreak: 21,
        totalCompletedDays: 45,
        week: [
            WeekdayStatus(symbol: "M", isCompleted: true),
            WeekdayStatus(symbol: "T", isCompleted: true),
            WeekdayStatus(symbol: "W", isCompleted: true),
            WeekdayStatus(symbol: "T", isCompleted: false),
            WeekdayStatus(symbol: "F", isCompleted: false),
            WeekdayStatus(symbol: "S", isCompleted: false),
            WeekdayStatus(symbol: "S", isCompleted: false)
        ]
    )
}

struct WeekdayStatus: Identifiable {
    let id = UUID()
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
                LinearGradient(
                    colors: [WidgetPalette.canvasTop, WidgetPalette.canvasBottom],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
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
        case .systemLarge:
            22
        default:
            18
        }
    }

    private var mediumWidget: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                compactHeader(titleFont: 11, valueFont: 28, iconSize: 44)

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Longest")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(WidgetPalette.secondaryText)
                    Text("\(entry.longestStreak)")
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundStyle(WidgetPalette.primaryText)
                }
            }

            Divider()
                .overlay(WidgetPalette.border.opacity(0.75))

            VStack(alignment: .leading, spacing: 10) {
                Text("THIS WEEK")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(WidgetPalette.primaryText)

                HStack(spacing: 8) {
                    ForEach(entry.week) { day in
                        weekdayDot(day, circleSize: 30, textSize: 11)
                    }
                }
            }
        }
    }

    private var largeWidget: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                compactHeader(titleFont: 13, valueFont: 40, iconSize: 52)

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Longest")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(WidgetPalette.secondaryText)
                    Text("\(entry.longestStreak)")
                        .font(.system(size: 30, weight: .semibold, design: .rounded))
                        .foregroundStyle(WidgetPalette.primaryText)
                }
            }

            VStack(spacing: 4) {
                Text("Total Days Completed")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(WidgetPalette.secondaryText)
                Text("\(entry.totalCompletedDays)")
                    .font(.system(size: 32, weight: .semibold, design: .rounded))
                    .foregroundStyle(WidgetPalette.primaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.white.opacity(0.28))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(WidgetPalette.border.opacity(0.7), lineWidth: 1)
            )

            Divider()
                .overlay(WidgetPalette.border.opacity(0.75))

            VStack(alignment: .leading, spacing: 14) {
                Text("THIS WEEK")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(WidgetPalette.primaryText)

                HStack(spacing: 10) {
                    ForEach(entry.week) { day in
                        weekdayDot(day, circleSize: 38, textSize: 12)
                    }
                }
            }
        }
    }

    private func compactHeader(titleFont: CGFloat, valueFont: CGFloat, iconSize: CGFloat) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(WidgetPalette.headerAccent.opacity(0.9))
                .frame(width: iconSize, height: iconSize)
                .overlay {
                    Image(systemName: "flame")
                        .font(.system(size: iconSize * 0.42, weight: .semibold))
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text("Current Streak")
                    .font(.system(size: titleFont, weight: .medium))
                    .foregroundStyle(WidgetPalette.secondaryText)
                Text("\(entry.currentStreak)")
                    .font(.system(size: valueFont, weight: .semibold, design: .rounded))
                    .foregroundStyle(WidgetPalette.primaryText)
            }
        }
    }

    private func weekdayDot(_ day: WeekdayStatus, circleSize: CGFloat, textSize: CGFloat) -> some View {
        VStack(spacing: 6) {
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
                            .font(.system(size: circleSize * 0.42, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }

            Text(day.symbol)
                .font(.system(size: textSize, weight: .semibold))
                .foregroundStyle(WidgetPalette.secondaryText)
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
        .description("Shows your streak, total completed days, and this week's progress.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

private enum WidgetPalette {
    static let canvasTop = Color(red: 0.95, green: 0.96, blue: 0.92)
    static let canvasBottom = Color(red: 0.93, green: 0.95, blue: 0.91)
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

