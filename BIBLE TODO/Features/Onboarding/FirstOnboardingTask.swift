import Foundation

/// Canonical first daily task for every new user. Must match a seeded `verse_tasks` row:
/// `verses.content->>'reference' == verseReference` and `category == categorySlug`
/// (see `project-bible-todo/sql/bible-todo-schema-and-seed-7-verses.sql`).
enum FirstOnboardingTask {
    static let verseReference = "Mark 12:31"
    static let categorySlug = "default"

    /// Shown on onboarding “first task” screen (keep in sync with seed title / description).
    static let taskTitle = "Love Someone Tangibly"
    static let taskDescription = "Do one concrete act of kindness for a neighbor, coworker, or family member today."

    /// Short verse line for the preview card.
    static let verseQuote = "\"Love your neighbor as yourself.\""
}
