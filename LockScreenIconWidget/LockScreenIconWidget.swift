//
//  LockScreenIconWidget.swift
//  LockScreenIconWidget
//
//  Created by Beena Vinod on 11/04/26.
//

import SwiftUI
import WidgetKit

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> LockScreenIconEntry {
        .preview(icon: LockScreenMilestoneIcon.unlockedDefaults[0])
    }

    func getSnapshot(in context: Context, completion: @escaping (LockScreenIconEntry) -> Void) {
        completion(.preview(icon: LockScreenMilestoneIcon.unlockedDefaults[0]))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LockScreenIconEntry>) -> Void) {
        let now = Date()
        let icons = LockScreenMilestoneIcon.unlockedDefaults
        let entries = icons.enumerated().map { index, icon in
            LockScreenIconEntry(
                date: Calendar.current.date(byAdding: .hour, value: index, to: now) ?? now,
                icon: icon,
                unlockedCount: icons.count
            )
        }

        let refreshDate = Calendar.current.date(byAdding: .hour, value: icons.count, to: now) ?? now.addingTimeInterval(60 * 60 * 2)
        completion(Timeline(entries: entries, policy: .after(refreshDate)))
    }
}

struct LockScreenIconEntry: TimelineEntry {
    let date: Date
    let icon: LockScreenMilestoneIcon
    let unlockedCount: Int

    static func preview(icon: LockScreenMilestoneIcon) -> LockScreenIconEntry {
        LockScreenIconEntry(date: .now, icon: icon, unlockedCount: LockScreenMilestoneIcon.unlockedDefaults.count)
    }
}

struct LockScreenMilestoneIcon: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let symbolName: String
    let milestone: String

    static let unlockedDefaults: [LockScreenMilestoneIcon] = [
        LockScreenMilestoneIcon(title: "Jesus", symbolName: "person.fill", milestone: "Unlocked"),
        LockScreenMilestoneIcon(title: "Cross", symbolName: "cross.case.fill", milestone: "3d")
    ]
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
    LockScreenIconEntry.preview(icon: .unlockedDefaults[0])
    LockScreenIconEntry.preview(icon: .unlockedDefaults[1])
}
