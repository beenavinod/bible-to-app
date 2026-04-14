import Foundation
import Combine
import SwiftUI

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published private(set) var selectedTheme: AppTheme
    @Published private(set) var selectedBackground: AppBackground
    @Published private(set) var widgetsEnabled: Bool

    let themes = AppTheme.allCases
    let backgrounds = AppBackground.allCases

    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
        selectedTheme = appState.theme
        selectedBackground = appState.background
        widgetsEnabled = appState.widgetsEnabled
    }

    func setTheme(_ theme: AppTheme) {
        selectedTheme = theme
        appState.setTheme(theme)
    }

    func setBackground(_ background: AppBackground) {
        selectedBackground = background
        appState.setBackground(background)
    }

    func setWidgetsEnabled(_ isEnabled: Bool) {
        widgetsEnabled = isEnabled
        appState.setWidgetsEnabled(isEnabled)
    }

    func signOut() async {
        await appState.signOut()
    }
}
