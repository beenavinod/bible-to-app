import Foundation

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

    func fetchBadgeDefinitions() async throws -> [Achievement] {
        BadgeIcons.fallbackCatalog
    }

    func fetchUserEarnedBadgeIds() async throws -> Set<Int> {
        []
    }

    func awardBadge(badgeDefinitionId: Int) async throws {}

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
            (-8, "Daily Verse", "Trust in the Lord with all your heart.", "Proverbs 3:5", "Walk in Trust", "Write one area where you need God's wisdom.", "\"Commit to the Lord whatever you do.\"", "figure.walk", true),
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
