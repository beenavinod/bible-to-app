import SwiftUI
import WidgetKit

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> VerseTaskEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (VerseTaskEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<VerseTaskEntry>) -> Void) {
        let entry = currentEntry()
        let nextUpdate = Calendar.current.nextDate(
            after: entry.date,
            matching: DateComponents(hour: 0, minute: 5),
            matchingPolicy: .nextTime
        ) ?? entry.date.addingTimeInterval(60 * 60 * 6)

        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func currentEntry() -> VerseTaskEntry {
        guard let data = WidgetDataStore.readVerseTask() else {
            return .placeholder
        }
        return VerseTaskEntry(
            date: .now,
            verseText: data.verseText,
            reference: data.reference,
            taskTitle: data.taskTitle,
            taskDescription: data.taskDescription,
            symbolName: data.symbolName
        )
    }
}

struct VerseTaskEntry: TimelineEntry {
    let date: Date
    let verseText: String
    let reference: String
    let taskTitle: String
    let taskDescription: String
    let symbolName: String

    static let placeholder = VerseTaskEntry(
        date: .now,
        verseText: "Let all that you do be done in love.",
        reference: "1 Corinthians 16:14",
        taskTitle: "Encourage Someone",
        taskDescription: "Send one meaningful message filled with hope.",
        symbolName: "message.badge.fill"
    )
}

struct VerseTaskWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: Provider.Entry

    var body: some View {
        content
            .padding(family == .systemSmall ? 14 : 18)
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
        case .systemSmall:
            smallWidget
        default:
            mediumWidget
        }
    }

    private var smallWidget: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("DAILY VERSE")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(WidgetPalette.secondaryText)

            Text("\"\(entry.verseText)\"")
                .font(.system(size: 14, weight: .medium, design: .serif))
                .foregroundStyle(WidgetPalette.primaryText)
                .lineSpacing(3)
                .lineLimit(4)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)

            Text(entry.reference)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(WidgetPalette.accentDark)
                .lineLimit(1)
        }
    }

    private var mediumWidget: some View {
        Group {
            if entry.taskTitle.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("DAILY VERSE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(WidgetPalette.secondaryText)

                    Text("\"\(entry.verseText)\"")
                        .font(.system(size: 17, weight: .medium, design: .serif))
                        .foregroundStyle(WidgetPalette.primaryText)
                        .lineSpacing(4)
                        .lineLimit(6)

                    Text(entry.reference)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(WidgetPalette.accentDark)
                        .lineLimit(2)

                    Spacer(minLength: 0)

                    Text("Open Bible Life to unlock today’s task with Premium.")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(WidgetPalette.secondaryText)
                        .lineLimit(3)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            } else {
                HStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("DAILY VERSE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(WidgetPalette.secondaryText)

                        Text("\"\(entry.verseText)\"")
                            .font(.system(size: 16, weight: .medium, design: .serif))
                            .foregroundStyle(WidgetPalette.primaryText)
                            .lineSpacing(4)
                            .lineLimit(5)

                        Text(entry.reference)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(WidgetPalette.accentDark)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.white.opacity(0.42))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(WidgetPalette.border.opacity(0.8), lineWidth: 1)
                        )
                        .overlay {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(alignment: .center, spacing: 10) {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(WidgetPalette.cardAccent)
                                        .frame(width: 34, height: 34)
                                        .overlay {
                                            Image(systemName: entry.symbolName)
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundStyle(WidgetPalette.accentDark)
                                        }

                                    Text("TODAY'S TASK")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(WidgetPalette.secondaryText)
                                }

                                Text(entry.taskTitle)
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundStyle(WidgetPalette.primaryText)
                                    .lineLimit(2)

                                Text(entry.taskDescription)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(WidgetPalette.secondaryText)
                                    .lineSpacing(2)
                                    .lineLimit(4)

                                Spacer(minLength: 0)
                            }
                            .padding(14)
                        }
                        .frame(width: 126)
                }
            }
        }
    }
}

struct VerseTaskWidget: Widget {
    let kind: String = "VerseTaskWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            VerseTaskWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Verse And Task")
        .description("Shows today's Bible verse and a simple action for the day.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

private enum WidgetPalette {
    static let canvasTop = Color(red: 0.97, green: 0.95, blue: 0.90)
    static let canvasBottom = Color(red: 0.92, green: 0.95, blue: 0.89)
    static let cardAccent = Color(red: 0.90, green: 0.94, blue: 0.86)
    static let primaryText = Color(red: 0.31, green: 0.27, blue: 0.22)
    static let secondaryText = Color(red: 0.47, green: 0.44, blue: 0.38)
    static let accentDark = Color(red: 0.45, green: 0.55, blue: 0.40)
    static let border = Color(red: 0.86, green: 0.82, blue: 0.74)
}

#Preview(as: .systemSmall) {
    VerseTaskWidget()
} timeline: {
    VerseTaskEntry.placeholder
}

#Preview(as: .systemMedium) {
    VerseTaskWidget()
} timeline: {
    VerseTaskEntry.placeholder
}
