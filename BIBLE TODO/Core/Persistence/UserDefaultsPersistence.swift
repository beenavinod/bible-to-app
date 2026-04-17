import Foundation

final class UserDefaultsPersistence: AppPersistence {
    private enum Key {
        static let completedIDs = "completedRecordIDs"
        static let selectedTheme = "selectedTheme"
        static let selectedBackground = "selectedBackground"
        static let selectedHomeWallpaper = "selectedHomeWallpaper"
        static let widgetsEnabled = "widgetsEnabled"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let preferredName = "preferredName"
        static let bibleReaderTheme = "bibleReaderTheme"
        static let bibleReaderFontScale = "bibleReaderFontScale"
        static let bibleReaderLineSpacingExtra = "bibleReaderLineSpacingExtra"
        static let lockScreenWidgetBadgeId = "lockScreenWidgetBadgeId"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func completedRecordIDs() -> Set<UUID> {
        let strings = defaults.stringArray(forKey: Key.completedIDs) ?? []
        return Set(strings.compactMap(UUID.init(uuidString:)))
    }

    func setCompletedRecordIDs(_ ids: Set<UUID>) {
        defaults.set(ids.map(\.uuidString), forKey: Key.completedIDs)
    }

    func selectedTheme() -> AppTheme {
        guard
            let rawValue = defaults.string(forKey: Key.selectedTheme),
            let theme = AppTheme(rawValue: rawValue)
        else {
            return .oliveMist
        }
        return theme
    }

    func setSelectedTheme(_ theme: AppTheme) {
        defaults.set(theme.rawValue, forKey: Key.selectedTheme)
    }

    func selectedBackground() -> AppBackground {
        guard
            let rawValue = defaults.string(forKey: Key.selectedBackground),
            let background = AppBackground(rawValue: rawValue)
        else {
            return .plain
        }
        return background
    }

    func setSelectedBackground(_ background: AppBackground) {
        defaults.set(background.rawValue, forKey: Key.selectedBackground)
    }

    func selectedHomeWallpaper() -> HomeWallpaper {
        guard
            let raw = defaults.string(forKey: Key.selectedHomeWallpaper),
            let wallpaper = HomeWallpaper(rawValue: raw)
        else {
            return .defaultWallpaper
        }
        return wallpaper
    }

    func setSelectedHomeWallpaper(_ wallpaper: HomeWallpaper) {
        defaults.set(wallpaper.rawValue, forKey: Key.selectedHomeWallpaper)
    }

    func widgetsEnabled() -> Bool {
        if defaults.object(forKey: Key.widgetsEnabled) == nil {
            return true
        }
        return defaults.bool(forKey: Key.widgetsEnabled)
    }

    func setWidgetsEnabled(_ isEnabled: Bool) {
        defaults.set(isEnabled, forKey: Key.widgetsEnabled)
    }

    func hasCompletedOnboarding() -> Bool {
        defaults.bool(forKey: Key.hasCompletedOnboarding)
    }

    func setHasCompletedOnboarding(_ hasCompleted: Bool) {
        defaults.set(hasCompleted, forKey: Key.hasCompletedOnboarding)
    }

    func preferredName() -> String? {
        defaults.string(forKey: Key.preferredName)
    }

    func setPreferredName(_ name: String?) {
        defaults.set(name, forKey: Key.preferredName)
    }

    func bibleReaderTheme() -> BibleReaderTheme {
        guard
            let raw = defaults.string(forKey: Key.bibleReaderTheme),
            let theme = BibleReaderTheme(rawValue: raw)
        else {
            return .mist
        }
        return theme
    }

    func setBibleReaderTheme(_ theme: BibleReaderTheme) {
        defaults.set(theme.rawValue, forKey: Key.bibleReaderTheme)
    }

    func bibleReaderFontScale() -> Double {
        let v = defaults.double(forKey: Key.bibleReaderFontScale)
        if v < 0.01 { return 1.0 }
        return min(max(v, 0.85), 1.45)
    }

    func setBibleReaderFontScale(_ value: Double) {
        defaults.set(min(max(value, 0.85), 1.45), forKey: Key.bibleReaderFontScale)
    }

    func bibleReaderLineSpacingExtra() -> Double {
        let v = defaults.double(forKey: Key.bibleReaderLineSpacingExtra)
        if defaults.object(forKey: Key.bibleReaderLineSpacingExtra) == nil { return 2 }
        return min(max(v, 0), 18)
    }

    func setBibleReaderLineSpacingExtra(_ value: Double) {
        defaults.set(min(max(value, 0), 18), forKey: Key.bibleReaderLineSpacingExtra)
    }

    func lockScreenWidgetBadgeId() -> Int? {
        guard let object = defaults.object(forKey: Key.lockScreenWidgetBadgeId) else { return nil }
        if let n = object as? NSNumber { return n.intValue }
        if let i = object as? Int { return i }
        return nil
    }

    func setLockScreenWidgetBadgeId(_ id: Int?) {
        if let id {
            defaults.set(id, forKey: Key.lockScreenWidgetBadgeId)
        } else {
            defaults.removeObject(forKey: Key.lockScreenWidgetBadgeId)
        }
    }
}
