import Foundation

protocol BibleService {
    func fetchTodayVerse() async throws -> Verse
    func fetchHistory() async throws -> [DailyRecord]
    func fetchStreakSummary() async throws -> StreakSummary
    /// Persists task completion via Supabase (`SupabaseBibleService`); throws when signed out.
    func syncTaskCompletion(userTaskId: UUID, assignedDateISO: String, completed: Bool) async throws
}

/// Used before sign-in or when Supabase is unavailable. All data methods fail fast (no fake data).
final class SignedOutBibleService: BibleService {
    func fetchTodayVerse() async throws -> Verse {
        throw BibleTodoRepositoryError.notAuthenticated
    }

    func fetchHistory() async throws -> [DailyRecord] {
        throw BibleTodoRepositoryError.notAuthenticated
    }

    func fetchStreakSummary() async throws -> StreakSummary {
        throw BibleTodoRepositoryError.notAuthenticated
    }

    func syncTaskCompletion(userTaskId: UUID, assignedDateISO: String, completed: Bool) async throws {
        _ = userTaskId
        _ = assignedDateISO
        _ = completed
        throw BibleTodoRepositoryError.notAuthenticated
    }
}

protocol AppPersistence {
    func completedRecordIDs() -> Set<UUID>
    func setCompletedRecordIDs(_ ids: Set<UUID>)
    func selectedTheme() -> AppTheme
    func setSelectedTheme(_ theme: AppTheme)
    func selectedBackground() -> AppBackground
    func setSelectedBackground(_ background: AppBackground)
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

final class UserDefaultsPersistence: AppPersistence {
    private enum Key {
        static let completedIDs = "completedRecordIDs"
        static let selectedTheme = "selectedTheme"
        static let selectedBackground = "selectedBackground"
        static let widgetsEnabled = "widgetsEnabled"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let preferredName = "preferredName"
        static let bibleReaderTheme = "bibleReaderTheme"
        static let bibleReaderFontScale = "bibleReaderFontScale"
        static let bibleReaderLineSpacingExtra = "bibleReaderLineSpacingExtra"
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
}

/// Sample data for **unit tests** and **SwiftUI previews** only — not used in the shipping app target flow.
final class MockBibleService: BibleService {
    private let calendar = Calendar.current
    private let records: [DailyRecord]

    init() {
        records = MockBibleService.makeRecords()
    }

    func fetchTodayVerse() async throws -> Verse {
        try await Task.sleep(for: .milliseconds(120))
        return records.first(where: { calendar.isDateInToday($0.verse.date) })?.verse ?? records[0].verse
    }

    func fetchHistory() async throws -> [DailyRecord] {
        try await Task.sleep(for: .milliseconds(140))
        return records.sorted { $0.verse.date > $1.verse.date }
    }

    func fetchStreakSummary() async throws -> StreakSummary {
        try await Task.sleep(for: .milliseconds(100))
        let completedRecords = records.filter(\.completed)
        let currentStreak = records
            .sorted { $0.verse.date > $1.verse.date }
            .prefix { $0.completed }
            .count

        return StreakSummary(
            currentStreak: currentStreak,
            longestStreak: 21,
            totalCompletedDays: completedRecords.count
        )
    }

    func syncTaskCompletion(userTaskId: UUID, assignedDateISO: String, completed: Bool) async throws {
        _ = userTaskId
        _ = assignedDateISO
        _ = completed
    }

    private static func makeRecords() -> [DailyRecord] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        let payloads: [(offset: Int, title: String, text: String, reference: String, task: String, description: String, quote: String, symbol: String, completed: Bool)] = [
            (0, "Daily Verse", "The Lord is my shepherd, I lack nothing. He makes me lie down in green pastures, he leads me beside quiet waters, he refreshes my soul.", "Psalm 23:1-3", "Give Thanks", "Write down 3 things you're grateful for today.", "\"Give thanks in all circumstances.\"", "pencil.and.list.clipboard", false),
            (-1, "Daily Verse", "Let all that you do be done in love.", "1 Corinthians 16:14", "Encourage Someone", "Send one meaningful message filled with hope.", "\"Let us not love with words or speech but with actions and in truth.\"", "message.badge.fill", true),
            (-2, "Daily Verse", "Be still, and know that I am God.", "Psalm 46:10", "Practice Stillness", "Spend five quiet minutes without distractions.", "\"In returning and rest you shall be saved.\"", "hands.clap.fill", true),
            (-3, "Daily Verse", "Your word is a lamp for my feet, a light on my path.", "Psalm 119:105", "Read Before Bed", "Read one short passage before sleeping.", "\"Blessed are those who hear the word of God and obey it.\"", "book.pages.fill", true),
            (-4, "Daily Verse", "The joy of the Lord is your strength.", "Nehemiah 8:10", "Celebrate Grace", "List one answered prayer from this week.", "\"Rejoice in the Lord always.\"", "sun.max.fill", true),
            (-7, "Daily Verse", "Cast all your anxiety on him because he cares for you.", "1 Peter 5:7", "Release Worry", "Pray through one burden and let it go.", "\"Do not be anxious about anything.\"", "leaf.fill", true),
            (-8, "Daily Verse", "Trust in the Lord with all your heart.", "Proverbs 3:5", "Walk in Trust", "Write one area where you need God’s wisdom.", "\"Commit to the Lord whatever you do.\"", "figure.walk", true),
            (-10, "Daily Verse", "Seek first his kingdom and his righteousness.", "Matthew 6:33", "Prioritize Prayer", "Begin your day with a short spoken prayer.", "\"Pray continually.\"", "sparkles", true),
            (-13, "Daily Verse", "I can do all this through him who gives me strength.", "Philippians 4:13", "Serve Today", "Do one quiet act of service for someone.", "\"Serve one another humbly in love.\"", "heart.text.square.fill", true),
            (-16, "Daily Verse", "The steadfast love of the Lord never ceases.", "Lamentations 3:22-23", "Reflect on Mercy", "Journal where you noticed mercy this week.", "\"His mercies never come to an end.\"", "drop.fill", true),
            (-20, "Daily Verse", "My grace is sufficient for you.", "2 Corinthians 12:9", "Rest in Grace", "Replace self-criticism with one prayer.", "\"Come to me, all who are weary.\"", "moon.stars.fill", true),
            (-28, "Daily Verse", "Blessed are the peacemakers.", "Matthew 5:9", "Make Peace", "Repair one small strained relationship.", "\"Pursue what makes for peace.\"", "person.2.wave.2.fill", false)
        ]

        return payloads.map { item in
            let date = calendar.date(byAdding: .day, value: item.offset, to: today) ?? today
            let verse = Verse(
                id: UUID(),
                date: date,
                title: item.title,
                text: item.text,
                reference: item.reference,
                taskTitle: item.task,
                taskDescription: item.description,
                taskQuote: item.quote,
                symbolName: item.symbol
            )

            return DailyRecord(id: UUID(), verse: verse, completed: item.completed)
        }
    }
}

/// Stable in-memory persistence for SwiftUI previews (avoids `UserDefaults` side effects and duplicate `AppState` issues).
final class PreviewPersistence: AppPersistence {
    private var completedIDs: Set<UUID> = []
    private var theme: AppTheme = .oliveMist
    private var background: AppBackground = .plain
    private var widgets: Bool = true
    private var onboardingDone: Bool = false
    private var name: String? = "Beena"

    func completedRecordIDs() -> Set<UUID> { completedIDs }
    func setCompletedRecordIDs(_ ids: Set<UUID>) { completedIDs = ids }
    func selectedTheme() -> AppTheme { theme }
    func setSelectedTheme(_ theme: AppTheme) { self.theme = theme }
    func selectedBackground() -> AppBackground { background }
    func setSelectedBackground(_ background: AppBackground) { self.background = background }
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
