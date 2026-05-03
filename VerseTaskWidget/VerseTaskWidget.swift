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
        let isPremium = WidgetDataStore.readPremiumUnlocked()
        let data = WidgetDataStore.readVerseTask()

        guard isPremium else {
            if let data {
                return VerseTaskEntry(
                    date: .now,
                    verseText: data.verseText,
                    reference: data.reference,
                    taskTitle: data.taskTitle,
                    taskDescription: data.taskDescription,
                    symbolName: data.symbolName,
                    isLocked: true,
                    isTaskCompleted: data.taskCompleted ?? false
                )
            }
            return .locked
        }

        guard let data else { return .placeholder }
        return VerseTaskEntry(
            date: .now,
            verseText: data.verseText,
            reference: data.reference,
            taskTitle: data.taskTitle,
            taskDescription: data.taskDescription,
            symbolName: data.symbolName,
            isLocked: false,
            isTaskCompleted: data.taskCompleted ?? false
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
    var isLocked: Bool = false
    let isTaskCompleted: Bool

    static let placeholder = VerseTaskEntry(
        date: .now,
        verseText: "Let all that you do be done in love.",
        reference: "1 Corinthians 16:14",
        taskTitle: "Encourage Someone",
        taskDescription: "Send one meaningful message filled with hope.",
        symbolName: "message.badge.fill",
        isTaskCompleted: false
    )

    static let placeholderTaskDone = VerseTaskEntry(
        date: .now,
        verseText: "Let all that you do be done in love.",
        reference: "1 Corinthians 16:14",
        taskTitle: "Encourage Someone",
        taskDescription: "Send one meaningful message filled with hope.",
        symbolName: "message.badge.fill",
        isTaskCompleted: true
    )

    static let locked = VerseTaskEntry(
        date: .now,
        verseText: "Let all that you do be done in love.",
        reference: "1 Corinthians 16:14",
        taskTitle: "Encourage Someone",
        taskDescription: "Send one meaningful message filled with hope.",
        symbolName: "message.badge.fill",
        isLocked: true,
        isTaskCompleted: false
    )
}

struct VerseTaskWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: Provider.Entry

    var body: some View {
        content
            .padding(family == .systemSmall ? 4 : 8)
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
        if entry.isLocked {
            lockedView
        } else {
            switch family {
            case .systemSmall:
                smallWidget
            default:
                mediumWidget
            }
        }
    }

    private var lockedView: some View {
        ZStack {
            unlockedContent
                .blur(radius: 8)
                .allowsHitTesting(false)
                .accessibilityHidden(true)

            Color.white.opacity(0.15)

            VStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.system(size: family == .systemSmall ? 22 : 26, weight: .medium))
                    .foregroundStyle(WidgetPalette.accentDark)

                Text("Bible Life")
                    .font(.system(size: family == .systemSmall ? 13 : 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(WidgetPalette.primaryText)

                Text("Subscribe to unlock")
                    .font(.system(size: family == .systemSmall ? 10 : 12, weight: .medium))
                    .foregroundStyle(WidgetPalette.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var unlockedContent: some View {
        switch family {
        case .systemSmall:
            smallWidget
        default:
            mediumWidget
        }
    }

    private var smallWidget: some View {
        VStack(alignment: .center, spacing: 3) {
            Text(entry.verseText)
                .font(.system(size: 11, weight: .medium, design: .serif))
                .foregroundStyle(WidgetPalette.primaryText)
                .lineSpacing(2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .minimumScaleFactor(0.5)

            Text(entry.reference)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(WidgetPalette.accentDark)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .lineLimit(2)
                .minimumScaleFactor(0.72)
        }
    }

    private var mediumWidget: some View {
        Group {
            if entry.taskTitle.isEmpty {
                Text("Open Bible Life to unlock today’s task with Premium.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(WidgetPalette.secondaryText)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .minimumScaleFactor(0.85)
                    .padding(.horizontal, 4)
            } else {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(entry.taskTitle)
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundStyle(WidgetPalette.primaryText)
                            .multilineTextAlignment(.leading)
                            .minimumScaleFactor(0.82)
                            .lineLimit(4)

                        if !entry.taskDescription.isEmpty {
                            Text(entry.taskDescription)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(WidgetPalette.secondaryText)
                                .lineSpacing(2)
                                .multilineTextAlignment(.leading)
                                .minimumScaleFactor(0.8)
                                .lineLimit(6)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    mediumTaskCompletionIcon
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
    }

    private var mediumTaskCompletionIcon: some View {
        Image(systemName: entry.isTaskCompleted ? "checkmark.circle.fill" : "circle")
            .font(.system(size: 34, weight: entry.isTaskCompleted ? .semibold : .regular))
            .foregroundStyle(
                entry.isTaskCompleted
                    ? WidgetPalette.accentDark
                    : WidgetPalette.secondaryText.opacity(0.55)
            )
            .accessibilityLabel(entry.isTaskCompleted ? "Task completed" : "Task not completed")
    }
}

struct VerseTaskWidget: Widget {
    let kind: String = "VerseTaskWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            VerseTaskWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Verse And Task")
        .description("Small: today’s verse. Medium: today’s task and completion.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

private enum WidgetPalette {
    static let canvasTop = Color(red: 0.97, green: 0.95, blue: 0.90)
    static let canvasBottom = Color(red: 0.92, green: 0.95, blue: 0.89)
    static let primaryText = Color(red: 0.31, green: 0.27, blue: 0.22)
    static let secondaryText = Color(red: 0.47, green: 0.44, blue: 0.38)
    static let accentDark = Color(red: 0.45, green: 0.55, blue: 0.40)
    static let border = Color(red: 0.86, green: 0.82, blue: 0.74)
}

#Preview("Small", as: .systemSmall) {
    VerseTaskWidget()
} timeline: {
    VerseTaskEntry.placeholder
}

#Preview("Medium", as: .systemMedium) {
    VerseTaskWidget()
} timeline: {
    VerseTaskEntry.placeholder
}

#Preview("Small Locked", as: .systemSmall) {
    VerseTaskWidget()
} timeline: {
    VerseTaskEntry.locked
}

#Preview("Medium Locked", as: .systemMedium) {
    VerseTaskWidget()
} timeline: {
    VerseTaskEntry.locked
}

#Preview("Medium task done", as: .systemMedium) {
    VerseTaskWidget()
} timeline: {
    VerseTaskEntry.placeholderTaskDone
}
