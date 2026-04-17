import Foundation

/// Stable in-memory persistence for SwiftUI previews (avoids `UserDefaults` side effects and duplicate `AppState` issues).
final class PreviewPersistence: AppPersistence {
    private var completedIDs: Set<UUID> = []
    private var theme: AppTheme = .oliveMist
    private var background: AppBackground = .plain
    private var homeWallpaper: HomeWallpaper = .defaultWallpaper
    private var widgets: Bool = true
    private var onboardingDone: Bool = false
    private var name: String? = "Beena"

    func completedRecordIDs() -> Set<UUID> { completedIDs }
    func setCompletedRecordIDs(_ ids: Set<UUID>) { completedIDs = ids }
    func selectedTheme() -> AppTheme { theme }
    func setSelectedTheme(_ theme: AppTheme) { self.theme = theme }
    func selectedBackground() -> AppBackground { background }
    func setSelectedBackground(_ background: AppBackground) { self.background = background }
    func selectedHomeWallpaper() -> HomeWallpaper { homeWallpaper }
    func setSelectedHomeWallpaper(_ wallpaper: HomeWallpaper) { homeWallpaper = wallpaper }
    func widgetsEnabled() -> Bool { widgets }
    func setWidgetsEnabled(_ isEnabled: Bool) { widgets = isEnabled }
    func hasCompletedOnboarding() -> Bool { onboardingDone }
    func setHasCompletedOnboarding(_ hasCompleted: Bool) { onboardingDone = hasCompleted }
    func preferredName() -> String? { name }
    func setPreferredName(_ name: String?) { self.name = name }

    private var bibleTheme: BibleReaderTheme = .mist
    private var bibleFontScale: Double = 1.0
    private var bibleLineExtra: Double = 2

    func bibleReaderTheme() -> BibleReaderTheme { bibleTheme }
    func setBibleReaderTheme(_ theme: BibleReaderTheme) { bibleTheme = theme }
    func bibleReaderFontScale() -> Double { bibleFontScale }
    func setBibleReaderFontScale(_ value: Double) { bibleFontScale = value }
    func bibleReaderLineSpacingExtra() -> Double { bibleLineExtra }
    func setBibleReaderLineSpacingExtra(_ value: Double) { bibleLineExtra = value }
}
