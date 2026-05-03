import Foundation

/// App Group suite identifier shared between the main app and all widget extensions.
private let appGroupSuiteID = "group.abvy.BIBLE-TODO"

// MARK: - Shared DTOs

/// Data written by the main app for the VerseTask home-screen widget.
struct SharedVerseTaskData: Codable {
    let verseText: String
    let reference: String
    let taskTitle: String
    let taskDescription: String
    let symbolName: String
    /// ISO 8601 date string (yyyy-MM-dd) for staleness checks.
    let dateISO: String
    /// Whether today’s task is done (medium widget status). Omitted in older payloads → treated as false.
    var taskCompleted: Bool? = nil
}

/// Week-day completion status for the streak widget.
struct SharedWeekDay: Codable {
    let symbol: String
    let isCompleted: Bool
}

/// Data written by the main app for the Streak home-screen widget.
struct SharedStreakData: Codable {
    let currentStreak: Int
    let longestStreak: Int
    let totalCompletedDays: Int
    /// Five rolling calendar days (day-of-month labels) for the **medium** widget.
    let weekDays: [SharedWeekDay]
    /// Seven days for the current locale week (short weekday initial) for the **large** widget; mirrors the share card strip.
    var calendarWeek: [SharedWeekDay]? = nil
}

/// A single unlocked achievement icon for the lock-screen widget.
struct SharedBadgeEntry: Codable {
    let symbolName: String
    let title: String
    let milestone: String
}

/// Data written by the main app for the LockScreenIcon widget.
struct SharedBadgeData: Codable {
    let badges: [SharedBadgeEntry]
}

// MARK: - WidgetDataStore

/// Reads and writes widget data through the App Group `UserDefaults` suite.
/// Both the main app (writer) and widget extensions (readers) use this type.
enum WidgetDataStore {
    private static let defaults = UserDefaults(suiteName: appGroupSuiteID)

    private enum Key {
        static let verseTask = "widget_verseTask"
        static let streak = "widget_streak"
        static let badges = "widget_badges"
        static let premiumUnlocked = "widget_premiumUnlocked"
    }

    // MARK: - Verse + Task

    /// Persists today's verse and task data for the VerseTask widget.
    static func writeVerseTask(_ data: SharedVerseTaskData) {
        write(data, forKey: Key.verseTask)
    }

    /// Reads the most recent verse/task data (returns `nil` when no data has been written).
    static func readVerseTask() -> SharedVerseTaskData? {
        read(SharedVerseTaskData.self, forKey: Key.verseTask)
    }

    // MARK: - Streak

    /// Persists streak summary and weekly progress for the Streak widget.
    static func writeStreak(_ data: SharedStreakData) {
        write(data, forKey: Key.streak)
    }

    /// Reads the most recent streak data (returns `nil` when no data has been written).
    static func readStreak() -> SharedStreakData? {
        read(SharedStreakData.self, forKey: Key.streak)
    }

    // MARK: - Badges

    /// Persists the user's unlocked achievement icons for the LockScreen widget.
    static func writeBadges(_ data: SharedBadgeData) {
        write(data, forKey: Key.badges)
    }

    /// Reads unlocked badge data (returns `nil` when no data has been written).
    static func readBadges() -> SharedBadgeData? {
        read(SharedBadgeData.self, forKey: Key.badges)
    }

    // MARK: - Premium (task on medium widget; verse on small)

    static func writePremiumUnlocked(_ isUnlocked: Bool) {
        defaults?.set(isUnlocked, forKey: Key.premiumUnlocked)
    }

    static func readPremiumUnlocked() -> Bool {
        defaults?.bool(forKey: Key.premiumUnlocked) ?? false
    }

    // MARK: - Helpers

    private static func write<T: Encodable>(_ value: T, forKey key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults?.set(data, forKey: key)
    }

    private static func read<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = defaults?.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
