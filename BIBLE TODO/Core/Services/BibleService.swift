import Foundation

protocol BibleService {
    /// Today’s row from `loadDailyContent` (creates `user_tasks` when missing), including the real `user_tasks.id`.
    func fetchTodayDailyRecord() async throws -> DailyRecord
    func fetchHistory() async throws -> [DailyRecord]
    func fetchStreakSummary() async throws -> StreakSummary
    func fetchBadgeDefinitions() async throws -> [Achievement]
    func fetchUserEarnedBadgeIds() async throws -> Set<Int>
    /// Single definition by id (used when bulk fetch is empty but the user still has an earned badge selected for widgets).
    func fetchBadgeDefinition(id: Int) async throws -> Achievement?
    func awardBadge(badgeDefinitionId: Int) async throws
    /// Persists task completion via Supabase (`SupabaseBibleService`); throws when signed out.
    func syncTaskCompletion(userTaskId: UUID, assignedDateISO: String, completed: Bool) async throws
}

extension BibleService {
    func fetchBadgeDefinition(id: Int) async throws -> Achievement? { nil }
}
