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

@Test func achievementIsUnlockedWhenCountMeetsThreshold() {
    let badge = Achievement(
        id: 1,
        slug: "task_streak_7",
        name: "Momentum",
        badgeDescription: "One week strong",
        type: .taskStreak,
        actionsRequired: 7,
        weight: 12,
        isActive: true
    )

    #expect(badge.isUnlocked(for: 6) == false)
    #expect(badge.isUnlocked(for: 7))
    #expect(badge.isUnlocked(for: 100))
}

@Test func achievementResolvesSymbolNameFromBadgeIcons() {
    let badge = Achievement(
        id: 1,
        slug: "task_streak_7",
        name: "Momentum",
        badgeDescription: "One week strong",
        type: .taskStreak,
        actionsRequired: 7,
        weight: 12,
        isActive: true
    )

    #expect(badge.symbolName == "star.fill")
}

@Test func achievementFallsBackToDefaultSymbolForUnknownSlug() {
    let badge = Achievement(
        id: 99,
        slug: "unknown_badge",
        name: "Unknown",
        badgeDescription: "Test",
        type: .taskStreak,
        actionsRequired: 1,
        weight: 0,
        isActive: true
    )

    #expect(badge.symbolName == "star.fill")
}

@Test func badgeIconsCoversAllSeedSlugs() {
    let expectedSlugs = [
        "task_streak_1", "task_streak_2", "task_streak_3", "task_streak_5",
        "task_streak_7", "task_streak_10", "task_streak_14", "task_streak_21",
        "task_streak_30", "task_streak_45", "task_streak_60", "task_streak_75",
        "task_streak_90", "task_streak_105", "task_streak_120", "task_streak_150",
        "task_streak_180", "task_streak_210", "task_streak_300", "task_streak_365",
        "verse_share_3", "first_share",
    ]

    for slug in expectedSlugs {
        #expect(BadgeIcons.forSlug[slug] != nil, "Missing icon for slug: \(slug)")
    }
}

@Test func badgeIconsHasNoEmptyValues() {
    for (slug, symbol) in BadgeIcons.forSlug {
        #expect(!symbol.isEmpty, "Empty symbol for slug: \(slug)")
    }
}

@Test func badgeDefinitionRowConvertsToAchievement() {
    let row = BadgeDefinitionRow(
        id: 5,
        slug: "task_streak_7",
        name: "Momentum",
        description: "One week strong",
        type: "task-streak",
        actionsRequired: 7,
        weight: 12,
        isActive: true
    )

    let achievement = row.toAchievement()
    #expect(achievement != nil)
    #expect(achievement?.id == 5)
    #expect(achievement?.slug == "task_streak_7")
    #expect(achievement?.type == .taskStreak)
    #expect(achievement?.actionsRequired == 7)
    #expect(achievement?.symbolName == "star.fill")
}

@Test func badgeDefinitionRowRejectsInvalidType() {
    let row = BadgeDefinitionRow(
        id: 99,
        slug: "invalid",
        name: "Bad",
        description: "Invalid type",
        type: "not-a-real-type",
        actionsRequired: 1,
        weight: 0,
        isActive: true
    )

    #expect(row.toAchievement() == nil)
}

@MainActor
@Test func mockBibleServiceReturnsFallbackBadges() async throws {
    let service = MockBibleService()
    let badges = try await service.fetchBadgeDefinitions()
    #expect(badges.count == BadgeIcons.fallbackCatalog.count)
    #expect(badges.count == 22)
}

@MainActor
@Test func mockBibleServiceReturnsEmptyEarnedBadgeIds() async throws {
    let service = MockBibleService()
    let earned = try await service.fetchUserEarnedBadgeIds()
    #expect(earned.isEmpty)
}

@Test func badgeTypeRawValuesMatchDatabaseConstraint() {
    #expect(BadgeType.taskStreak.rawValue == "task-streak")
    #expect(BadgeType.verseShare.rawValue == "verse-share")
    #expect(BadgeType.firstShare.rawValue == "first-share")
}

@Test func achievementHashableConformance() {
    let badge1 = Achievement(id: 1, slug: "task_streak_1", name: "First Step", badgeDescription: "The journey begins", type: .taskStreak, actionsRequired: 1, weight: 1, isActive: true)
    let badge2 = Achievement(id: 1, slug: "task_streak_1", name: "First Step", badgeDescription: "The journey begins", type: .taskStreak, actionsRequired: 1, weight: 1, isActive: true)
    let badge3 = Achievement(id: 2, slug: "task_streak_2", name: "Ignition", badgeDescription: "You showed up again", type: .taskStreak, actionsRequired: 2, weight: 3, isActive: true)

    #expect(badge1 == badge2)
    #expect(badge1 != badge3)

    let set: Set<Achievement> = [badge1, badge2, badge3]
    #expect(set.count == 2)
}

@Test func badgeRarityFromWeight() {
    #expect(BadgeRarity(weight: 1) == .common)
    #expect(BadgeRarity(weight: 20) == .common)
    #expect(BadgeRarity(weight: 27) == .common)
    #expect(BadgeRarity(weight: 28) == .rare)
    #expect(BadgeRarity(weight: 75) == .rare)
    #expect(BadgeRarity(weight: 90) == .epic)
    #expect(BadgeRarity(weight: 165) == .epic)
    #expect(BadgeRarity(weight: 185) == .legendary)
    #expect(BadgeRarity(weight: 300) == .legendary)
}

@Test func fallbackCatalogHasUniqueSlugs() {
    let slugs = BadgeIcons.fallbackCatalog.map(\.slug)
    #expect(Set(slugs).count == slugs.count)
}

@Test func fallbackCatalogCoversAllIconSlugs() {
    let catalogSlugs = Set(BadgeIcons.fallbackCatalog.map(\.slug))
    let iconSlugs = Set(BadgeIcons.forSlug.keys)
    #expect(catalogSlugs == iconSlugs)
}

@Test func achievementRarityMatchesWeight() {
    let common = Achievement(id: 1, slug: "task_streak_1", name: "First Step", badgeDescription: "Test", type: .taskStreak, actionsRequired: 1, weight: 1, isActive: true)
    let rare = Achievement(id: 8, slug: "task_streak_21", name: "Steady", badgeDescription: "Test", type: .taskStreak, actionsRequired: 21, weight: 28, isActive: true)
    let epic = Achievement(id: 13, slug: "task_streak_90", name: "Renewed", badgeDescription: "Test", type: .taskStreak, actionsRequired: 90, weight: 90, isActive: true)
    let legendary = Achievement(id: 19, slug: "task_streak_300", name: "Mastery", badgeDescription: "Test", type: .taskStreak, actionsRequired: 300, weight: 240, isActive: true)

    #expect(common.rarity == .common)
    #expect(rare.rarity == .rare)
    #expect(epic.rarity == .epic)
    #expect(legendary.rarity == .legendary)
}
