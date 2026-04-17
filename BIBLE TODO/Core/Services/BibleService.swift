import Foundation

protocol BibleService {
    func fetchTodayVerse() async throws -> Verse
    func fetchHistory() async throws -> [DailyRecord]
    func fetchStreakSummary() async throws -> StreakSummary
    func fetchBadgeDefinitions() async throws -> [Achievement]
    func fetchUserEarnedBadgeIds() async throws -> Set<Int>
    func awardBadge(badgeDefinitionId: Int) async throws
    /// Persists task completion via Supabase (`SupabaseBibleService`); throws when signed out.
    func syncTaskCompletion(userTaskId: UUID, assignedDateISO: String, completed: Bool) async throws
}
