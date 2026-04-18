import Foundation
import Combine
import SwiftUI

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published private(set) var widgetsEnabled: Bool

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
