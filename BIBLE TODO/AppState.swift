import Foundation
import Combine
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published private(set) var theme: AppTheme
    @Published private(set) var background: AppBackground
    @Published private(set) var widgetsEnabled: Bool

    let service: BibleService

    private let persistence: AppPersistence

    init(service: BibleService, persistence: AppPersistence) {
        self.service = service
        self.persistence = persistence
        theme = persistence.selectedTheme()
        background = persistence.selectedBackground()
        widgetsEnabled = persistence.widgetsEnabled()
    }

    var palette: AppThemePalette {
        theme.palette
    }

    func setTheme(_ theme: AppTheme) {
        self.theme = theme
        persistence.setSelectedTheme(theme)
    }

    func setBackground(_ background: AppBackground) {
        self.background = background
        persistence.setSelectedBackground(background)
    }

    func setWidgetsEnabled(_ isEnabled: Bool) {
        widgetsEnabled = isEnabled
        persistence.setWidgetsEnabled(isEnabled)
    }
}
