import Foundation

/// Life-stage slugs stored in `profiles.onboarding_data.category` and matched to `verse_tasks.category`.
enum BibleLifeCategory {
    /// Universal tasks in seed data; used when the profile has no category or an unknown slug.
    static let defaultSlug = "default"

    /// Slugs that have rows in the MVP seed script (`project-bible-todo/sql/bible-todo-schema-and-seed-7-verses.sql`).
    static let seededSlugs: Set<String> = [
        "default",
        "student",
        "working-professional",
        "parent"
    ]

    /// Returns a slug that has verse tasks in the database for the current seed, otherwise `defaultSlug`.
    static func resolvedSlug(stored: String?) -> String {
        guard let stored, seededSlugs.contains(stored) else { return defaultSlug }
        return stored
    }
}
