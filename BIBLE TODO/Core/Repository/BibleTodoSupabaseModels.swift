import Foundation

// MARK: - Errors

enum BibleTodoRepositoryError: LocalizedError, Equatable {
    case noVerseAvailable
    case notAuthenticated
    case invalidConfiguration

    var errorDescription: String? {
        switch self {
        case .noVerseAvailable:
            "No verse task is available for your category."
        case .notAuthenticated:
            "You need to sign in again."
        case .invalidConfiguration:
            "Supabase is not configured."
        }
    }
}

// MARK: - Profile

struct ProfileRow: Decodable, Sendable {
    let id: UUID
    let onboardingCompleted: Bool
    let onboardingData: OnboardingDataJSON
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case onboardingCompleted = "onboarding_completed"
        case onboardingData = "onboarding_data"
        case createdAt = "created_at"
    }
}

struct OnboardingDataJSON: Codable, Sendable, Equatable {
    var displayName: String?
    var dateOfBirth: String?
    var gender: String?
    var category: String?

    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
        case dateOfBirth = "date_of_birth"
        case gender
        case category
    }
}

/// Payload written to `profiles.onboarding_data` on completion (snake_case JSON keys).
struct OnboardingRemotePayload: Encodable, Sendable {
    let display_name: String
    let date_of_birth: String
    let gender: String
    let category: String
}

struct ProfileOnboardingUpdate: Encodable, Sendable {
    let onboarding_data: OnboardingRemotePayload
    let onboarding_completed: Bool
}

// MARK: - Verse / task joins

struct VerseContent: Decodable, Sendable {
    let text: String
    let reference: String
    let book: String
    let chapter: Int
    let verseStart: Int
    let verseEnd: Int?
    let translation: String
    let displayOrder: Int
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case text, reference, book, chapter, translation
        case verseStart = "verse_start"
        case verseEnd = "verse_end"
        case displayOrder = "display_order"
        case isActive = "is_active"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        text = try c.decode(String.self, forKey: .text)
        reference = try c.decode(String.self, forKey: .reference)
        book = try Self.decodeStringOrEmpty(c, forKey: .book)
        chapter = try Self.decodeIntFlex(c, forKey: .chapter) ?? 0
        verseStart = try Self.decodeIntFlex(c, forKey: .verseStart) ?? 1
        verseEnd = try Self.decodeIntFlex(c, forKey: .verseEnd)
        translation = try Self.decodeStringOrEmpty(c, forKey: .translation, default: "WEB")
        displayOrder = try Self.decodeIntFlex(c, forKey: .displayOrder) ?? 0
        isActive = try Self.decodeBoolFlex(c, forKey: .isActive) ?? true
    }

    private static func decodeStringOrEmpty(_ c: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys, default def: String = "") throws -> String {
        if let s = try c.decodeIfPresent(String.self, forKey: key) { return s }
        if let i = try c.decodeIfPresent(Int.self, forKey: key) { return String(i) }
        return def
    }

    private static func decodeIntFlex(_ c: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) throws -> Int? {
        if let v = try c.decodeIfPresent(Int.self, forKey: key) { return v }
        if let d = try c.decodeIfPresent(Double.self, forKey: key) { return Int(d) }
        if let s = try c.decodeIfPresent(String.self, forKey: key) {
            return Int(s.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return nil
    }

    private static func decodeBoolFlex(_ c: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) throws -> Bool? {
        if let b = try c.decodeIfPresent(Bool.self, forKey: key) { return b }
        if let i = try c.decodeIfPresent(Int.self, forKey: key) { return i != 0 }
        return nil
    }
}

struct VerseResponse: Decodable, Sendable {
    let id: UUID
    let content: VerseContent
}

struct VerseTaskWithVerse: Decodable, Sendable {
    let id: UUID
    let title: String
    let description: String
    let category: String
    let verses: VerseResponse

    enum CodingKeys: String, CodingKey {
        case id, title, description, category, verses
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        title = try c.decodeIfPresent(String.self, forKey: .title) ?? ""
        description = try c.decodeIfPresent(String.self, forKey: .description) ?? ""
        category = try c.decodeIfPresent(String.self, forKey: .category) ?? "default"
        verses = try Self.decodeVersesEmbedded(c)
    }

    /// PostgREST usually returns one joined `verses` row as an object; some responses use a single-element array.
    private static func decodeVersesEmbedded(_ c: KeyedDecodingContainer<CodingKeys>) throws -> VerseResponse {
        if let one = try? c.decode(VerseResponse.self, forKey: .verses) {
            return one
        }
        var nested = try c.nestedUnkeyedContainer(forKey: .verses)
        if nested.isAtEnd {
            throw DecodingError.dataCorruptedError(forKey: .verses, in: c, debugDescription: "verses embed is empty")
        }
        return try nested.decode(VerseResponse.self)
    }
}

typealias VerseTaskCandidate = VerseTaskWithVerse

struct UserTaskWithDetails: Decodable, Sendable {
    let id: UUID
    let assignedDate: String
    let status: String
    let completedAt: String?
    let verseTasks: VerseTaskWithVerse

    enum CodingKeys: String, CodingKey {
        case id, status
        case assignedDate = "assigned_date"
        case completedAt = "completed_at"
        case verseTasks = "verse_tasks"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        assignedDate = try c.decode(String.self, forKey: .assignedDate)
        status = try c.decode(String.self, forKey: .status)
        completedAt = try c.decodeIfPresent(String.self, forKey: .completedAt)
        verseTasks = try Self.decodeVerseTasksEmbedded(c)
    }

    private static func decodeVerseTasksEmbedded(_ c: KeyedDecodingContainer<CodingKeys>) throws -> VerseTaskWithVerse {
        if let one = try? c.decode(VerseTaskWithVerse.self, forKey: .verseTasks) {
            return one
        }
        var nested = try c.nestedUnkeyedContainer(forKey: .verseTasks)
        if nested.isAtEnd {
            throw DecodingError.dataCorruptedError(forKey: .verseTasks, in: c, debugDescription: "verse_tasks embed is empty")
        }
        return try nested.decode(VerseTaskWithVerse.self)
    }
}

struct ExistingTaskId: Decodable, Sendable {
    let verseTaskId: UUID

    enum CodingKeys: String, CodingKey {
        case verseTaskId = "verse_task_id"
    }
}

struct UserTaskInsert: Encodable, Sendable {
    let userId: UUID
    let verseTaskId: UUID
    let assignedDate: String
    let status: String
    /// When set, included as `completed_at` (omit key when `nil` so PostgREST does not receive null).
    let completedAt: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case verseTaskId = "verse_task_id"
        case assignedDate = "assigned_date"
        case status
        case completedAt = "completed_at"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userId, forKey: .userId)
        try container.encode(verseTaskId, forKey: .verseTaskId)
        try container.encode(assignedDate, forKey: .assignedDate)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(completedAt, forKey: .completedAt)
    }
}

// MARK: - Cached daily content (UserDefaults)

struct DailyContentCache: Codable, Equatable, Sendable {
    var userTaskId: UUID
    var assignedDate: String
    var status: String
    var completedAt: String?
    var verseId: UUID
    var verseText: String
    var verseReference: String
    var taskTitle: String
    var taskDescription: String
    var taskCategory: String

    enum CodingKeys: String, CodingKey {
        case userTaskId = "user_task_id"
        case assignedDate = "assigned_date"
        case status
        case completedAt = "completed_at"
        case verseId = "verse_id"
        case verseText = "verse_text"
        case verseReference = "verse_reference"
        case taskTitle = "task_title"
        case taskDescription = "task_description"
        case taskCategory = "task_category"
    }
}

// MARK: - Streaks

struct UserStreakRow: Decodable, Sendable {
    let currentStreak: Int
    let longestStreak: Int
    let lastCompletedDate: String?

    enum CodingKeys: String, CodingKey {
        case currentStreak = "current_streak"
        case longestStreak = "longest_streak"
        case lastCompletedDate = "last_completed_date"
    }
}

struct StreakInfo: Equatable, Sendable {
    let currentStreak: Int
    let longestStreak: Int
    let isNewMilestone: Bool
}

struct AssignedDateOnly: Decodable, Sendable {
    let assignedDate: String

    enum CodingKeys: String, CodingKey {
        case assignedDate = "assigned_date"
    }
}

// MARK: - Badge Definitions

/// Row decoded from the `badge_definitions` table.
struct BadgeDefinitionRow: Decodable, Sendable {
    let id: Int
    let slug: String
    let name: String
    let description: String
    let type: String
    let actionsRequired: Int
    let weight: Int
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id, slug, name, description, type, weight
        case actionsRequired = "actions_required"
        case isActive = "is_active"
    }

    /// Converts to the client-side `Achievement` model.
    func toAchievement() -> Achievement? {
        guard let badgeType = BadgeType(rawValue: type) else { return nil }
        return Achievement(
            id: id,
            slug: slug,
            name: name,
            badgeDescription: description,
            type: badgeType,
            actionsRequired: actionsRequired,
            weight: weight,
            isActive: isActive
        )
    }
}

// MARK: - User Badges

/// Row decoded from the `user_badges` table.
struct UserBadgeRow: Decodable, Sendable {
    let id: UUID
    let userId: UUID
    let badgeDefinitionId: Int
    let earnedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case badgeDefinitionId = "badge_definition_id"
        case earnedAt = "earned_at"
    }
}

/// Payload for inserting a row into `user_badges`.
struct UserBadgeInsert: Encodable, Sendable {
    let userId: UUID
    let badgeDefinitionId: Int

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case badgeDefinitionId = "badge_definition_id"
    }
}
