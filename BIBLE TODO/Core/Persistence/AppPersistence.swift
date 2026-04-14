import Foundation

protocol AppPersistence {
    func completedRecordIDs() -> Set<UUID>
    func setCompletedRecordIDs(_ ids: Set<UUID>)
    func selectedTheme() -> AppTheme
    func setSelectedTheme(_ theme: AppTheme)
    func selectedBackground() -> AppBackground
    func setSelectedBackground(_ background: AppBackground)
    func selectedHomeWallpaper() -> HomeWallpaper
    func setSelectedHomeWallpaper(_ wallpaper: HomeWallpaper)
    func widgetsEnabled() -> Bool
    func setWidgetsEnabled(_ isEnabled: Bool)
    func hasCompletedOnboarding() -> Bool
    func setHasCompletedOnboarding(_ hasCompleted: Bool)
    func preferredName() -> String?
    func setPreferredName(_ name: String?)

    /// WEB reader only (`BibleReaderTheme`).
    func bibleReaderTheme() -> BibleReaderTheme
    func setBibleReaderTheme(_ theme: BibleReaderTheme)
    /// 0.85 … 1.45, default 1.0
    func bibleReaderFontScale() -> Double
    func setBibleReaderFontScale(_ value: Double)
    /// Extra line spacing in points, 0 … 18, default 4
    func bibleReaderLineSpacingExtra() -> Double
    func setBibleReaderLineSpacingExtra(_ value: Double)
}
