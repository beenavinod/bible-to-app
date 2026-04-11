import Testing
@testable import BIBLE_TODO

@MainActor
@Test func mockBibleServiceProvidesHistoryAndTodayVerse() async throws {
    let service = MockBibleService()

    let todayVerse = try await service.fetchTodayVerse()
    let history = try await service.fetchHistory()
    let summary = try await service.fetchStreakSummary()

    #expect(history.isEmpty == false)
    #expect(history.contains(where: { $0.verse.id == todayVerse.id }))
    #expect(summary.totalCompletedDays > 0)
}

@Test func achievementsUnlockAgainstCurrentStreak() {
    let cross = Achievement.defaults[0]
    let church = Achievement.defaults[3]

    #expect(cross.isUnlocked(for: 3))
    #expect(church.isUnlocked(for: 9) == false)
}
