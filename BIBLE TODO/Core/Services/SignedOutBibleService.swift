import Foundation

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

    func fetchBadgeDefinitions() async throws -> [Achievement] {
        throw BibleTodoRepositoryError.notAuthenticated
    }

    func fetchUserEarnedBadgeIds() async throws -> Set<Int> {
        throw BibleTodoRepositoryError.notAuthenticated
    }

    func awardBadge(badgeDefinitionId: Int) async throws {
        throw BibleTodoRepositoryError.notAuthenticated
    }

    func syncTaskCompletion(userTaskId: UUID, assignedDateISO: String, completed: Bool) async throws {
        _ = userTaskId
        _ = assignedDateISO
        _ = completed
        throw BibleTodoRepositoryError.notAuthenticated
    }
}
