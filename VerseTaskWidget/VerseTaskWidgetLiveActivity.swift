//
//  VerseTaskWidgetLiveActivity.swift
//  VerseTaskWidget
//
//  Created by Beena Vinod on 11/04/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct VerseTaskWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct VerseTaskWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: VerseTaskWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension VerseTaskWidgetAttributes {
    fileprivate static var preview: VerseTaskWidgetAttributes {
        VerseTaskWidgetAttributes(name: "World")
    }
}

extension VerseTaskWidgetAttributes.ContentState {
    fileprivate static var smiley: VerseTaskWidgetAttributes.ContentState {
        VerseTaskWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: VerseTaskWidgetAttributes.ContentState {
         VerseTaskWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: VerseTaskWidgetAttributes.preview) {
   VerseTaskWidgetLiveActivity()
} contentStates: {
    VerseTaskWidgetAttributes.ContentState.smiley
    VerseTaskWidgetAttributes.ContentState.starEyes
}
