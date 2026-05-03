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

/// Calendar-day streak logic shared by the Journey UI, mocks, and widgets fed from the same rules.
enum StreakCalculation {
    /// Counts consecutive local calendar days with at least one completed task, walking backward from `reference`.
    /// If `reference` has no completion, counts from the previous day (streak still "alive" until that day ends).
    static func consecutiveCompletedDayStreak(records: [DailyRecord], reference: Date = .now) -> Int {
        let cal = Calendar.current
        let completedDays = Set(
            records.filter(\.completed).map { cal.startOfDay(for: $0.verse.date) }
        )
        guard !completedDays.isEmpty else { return 0 }

        let todayStart = cal.startOfDay(for: reference)
        var anchor = todayStart
        if !completedDays.contains(anchor) {
            guard let yesterday = cal.date(byAdding: .day, value: -1, to: todayStart) else { return 0 }
            anchor = yesterday
            guard completedDays.contains(anchor) else { return 0 }
        }

        var count = 0
        var d = anchor
        while completedDays.contains(d) {
            count += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: d) else { break }
            d = prev
        }
        return count
    }
}
