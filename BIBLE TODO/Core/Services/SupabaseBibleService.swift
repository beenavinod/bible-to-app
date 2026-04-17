import Foundation

extension DailyContentCache {
    fileprivate static func symbolName(forCategory category: String) -> String {
        switch category {
        case "default": "sparkles"
        case "student": "book.fill"
        case "working-professional": "briefcase.fill"
        case "parent": "figure.and.child.holdinghands"
        case "church-leader": "building.columns.fill"
        case "homemaker": "house.fill"
        case "retired-senior": "heart.text.square.fill"
        default: "sparkles"
        }
    }

    func toDailyRecord(completedOverride: Bool? = nil) -> DailyRecord {
        let day = BibleTodoDate.parseLocalDay(assignedDate) ?? Calendar.current.startOfDay(for: Date())
        let done = completedOverride ?? (status == "completed")
        let verse = Verse(
            id: verseId,
            date: day,
            title: "Daily Verse",
            text: verseText,
            reference: verseReference,
            taskTitle: taskTitle,
            taskDescription: taskDescription,
            taskQuote: "",
            symbolName: Self.symbolName(forCategory: taskCategory)
        )
        return DailyRecord(id: userTaskId, verse: verse, completed: done)
    }
}

/// `BibleService` backed by Supabase (`BibleTodoRepository`).
final class SupabaseBibleService: BibleService {
    private let userId: UUID
    private let category: String
    private let repository: BibleTodoRepository

    init(userId: UUID, category: String, repository: BibleTodoRepository) {
        self.userId = userId
        self.category = category
        self.repository = repository
    }

    func fetchTodayDailyRecord() async throws -> DailyRecord {
        let cache = try await repository.loadDailyContent(userId: userId, category: category)
        return cache.toDailyRecord()
    }

    func fetchHistory() async throws -> [DailyRecord] {
        let rows = try await repository.fetchHistory(userId: userId)
        return rows.map { row in
            BibleTodoRepository.mapToCache(row).toDailyRecord()
        }
    }

    func fetchStreakSummary() async throws -> StreakSummary {
        try await repository.fetchStreakSummary(userId: userId)
    }

    func fetchBadgeDefinitions() async throws -> [Achievement] {
        let rows = try await repository.fetchBadgeDefinitions()
        return rows.compactMap { $0.toAchievement() }
    }

    func fetchUserEarnedBadgeIds() async throws -> Set<Int> {
        try await repository.fetchUserEarnedBadgeIds(userId: userId)
    }

    func awardBadge(badgeDefinitionId: Int) async throws {
        try await repository.awardBadge(userId: userId, badgeDefinitionId: badgeDefinitionId)
    }

    func syncTaskCompletion(userTaskId: UUID, assignedDateISO: String, completed: Bool) async throws {
        if completed {
            _ = try await repository.completeTask(userId: userId, userTaskId: userTaskId, date: assignedDateISO)
        } else {
            try await repository.undoTaskCompletion(userId: userId, userTaskId: userTaskId, date: assignedDateISO)
        }
    }
}
