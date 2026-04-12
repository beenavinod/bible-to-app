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
