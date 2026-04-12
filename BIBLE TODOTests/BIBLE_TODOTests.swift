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

@Test func webBibleMergesDuplicateVerseNumbers() {
    let rows = [
        WEBBibleVerseRecord(n: 1, t: "First line."),
        WEBBibleVerseRecord(n: 1, t: "Second line."),
        WEBBibleVerseRecord(n: 2, t: "Next verse."),
    ]
    let merged = WEBBibleVerseRecord.mergedUniqueVerses(rows)
    #expect(merged.count == 2)
    #expect(merged[0].n == 1)
    #expect(merged[0].t.contains("First line"))
    #expect(merged[0].t.contains("Second line"))
    #expect(merged[1].n == 2)
}

@Test func achievementsUnlockAgainstCurrentStreak() {
    let cross = Achievement.defaults[0]
    let church = Achievement.defaults[3]

    #expect(cross.isUnlocked(for: 3))
    #expect(church.isUnlocked(for: 9) == false)
}
