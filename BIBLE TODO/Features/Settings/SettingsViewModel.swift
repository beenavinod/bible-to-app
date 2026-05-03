import Foundation
import Combine
import SwiftUI

struct WidgetInfo: Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let symbolName: String
    let isPremiumOnly: Bool
}

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published private(set) var widgetsEnabled: Bool

    let widgets: [WidgetInfo] = [
        WidgetInfo(
            id: "StreakWidget",
            name: "Bible Streak",
            description: "Your streak and weekly progress",
            symbolName: "flame.fill",
            isPremiumOnly: false
        ),
        WidgetInfo(
            id: "VerseTaskWidget",
            name: "Verse & Task",
            description: "Daily verse and today's action",
            symbolName: "text.book.closed.fill",
            isPremiumOnly: true
        ),
        WidgetInfo(
            id: "LockScreenIconWidget",
            name: "Badge Icon",
            description: "Achievement badge on Lock Screen",
            symbolName: "lock.circle.fill",
            isPremiumOnly: false
        ),
    ]

    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
        widgetsEnabled = appState.widgetsEnabled
    }

    func setWidgetsEnabled(_ isEnabled: Bool) {
        widgetsEnabled = isEnabled
        appState.setWidgetsEnabled(isEnabled)
    }

    func signOut() async {
        await appState.signOut()
    }
}
