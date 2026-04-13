import SwiftUI
import WidgetKit

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> LockScreenIconEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (LockScreenIconEntry) -> Void) {
        let entries = buildEntries()
        completion(entries.first ?? .placeholder)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LockScreenIconEntry>) -> Void) {
        let entries = buildEntries()
        guard !entries.isEmpty else {
            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? Date.now.addingTimeInterval(3600)
            completion(Timeline(entries: [.placeholder], policy: .after(nextUpdate)))
            return
        }
        let refreshDate = Calendar.current.date(byAdding: .hour, value: entries.count, to: .now)
            ?? Date.now.addingTimeInterval(Double(entries.count) * 3600)
        completion(Timeline(entries: entries, policy: .after(refreshDate)))
    }

    private func buildEntries() -> [LockScreenIconEntry] {
        guard let data = WidgetDataStore.readBadges(), !data.badges.isEmpty else {
            return []
        }
        let now = Date()
        return data.badges.enumerated().map { index, badge in
            LockScreenIconEntry(
                date: Calendar.current.date(byAdding: .hour, value: index, to: now) ?? now,
                icon: LockScreenMilestoneIcon(
                    title: badge.title,
                    symbolName: badge.symbolName,
                    milestone: badge.milestone
                ),
                unlockedCount: data.badges.count
            )
        }
    }
}

struct LockScreenIconEntry: TimelineEntry {
    let date: Date
    let icon: LockScreenMilestoneIcon
    let unlockedCount: Int

    static let placeholder = LockScreenIconEntry(
        date: .now,
        icon: LockScreenMilestoneIcon(title: "Bible Life", symbolName: "book.closed.fill", milestone: "Start"),
        unlockedCount: 0
    )
}

struct LockScreenMilestoneIcon: Equatable {
    let title: String
    let symbolName: String
    let milestone: String
}

struct LockScreenIconWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: Provider.Entry

    var body: some View {
        content
            .containerBackground(for: .widget) {
                Color.clear
            }
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .accessoryCircular:
            accessoryCircularView
        default:
            accessoryCircularView
        }
    }

    private var accessoryCircularView: some View {
        ZStack {
            AccessoryWidgetBackground()

            VStack(spacing: 2) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: entry.icon.symbolName)
                        .font(.system(size: 22, weight: .semibold))
                        .widgetAccentable()

                    if entry.unlockedCount > 1 {
                        Text("\(entry.unlockedCount)")
                            .font(.system(size: 8, weight: .bold, design: .rounded))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(Color.white.opacity(0.22)))
                            .offset(x: 10, y: -6)
                    }
                }

                Text(entry.icon.title)
                    .font(.system(size: 8, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(entry.icon.milestone)
                    .font(.system(size: 7, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(6)
        }
    }
}

struct LockScreenIconWidget: Widget {
    let kind: String = "LockScreenIconWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            LockScreenIconWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Unlocked Icon")
        .description("Shows a currently unlocked streak milestone icon on the Lock Screen.")
        .supportedFamilies([.accessoryCircular])
    }
}

#Preview(as: .accessoryCircular) {
    LockScreenIconWidget()
} timeline: {
    LockScreenIconEntry.placeholder
}
