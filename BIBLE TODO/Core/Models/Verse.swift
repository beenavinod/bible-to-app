import Foundation

struct Verse: Identifiable, Codable, Equatable {
    let id: UUID
    let date: Date
    let title: String
    let text: String
    let reference: String
    let taskTitle: String
    let taskDescription: String
    let taskQuote: String
    let symbolName: String
}

struct DailyRecord: Identifiable, Codable, Equatable {
    let id: UUID
    let verse: Verse
    let completed: Bool
}

struct StreakSummary: Codable, Equatable {
    let currentStreak: Int
    let longestStreak: Int
    let totalCompletedDays: Int
}
