import Foundation
import Combine
import SwiftUI
import WidgetKit

@MainActor
final class JourneyViewModel: ObservableObject {
    @Published private(set) var records: [DailyRecord] = []
    @Published private(set) var summary = StreakSummary(currentStreak: 0, longestStreak: 0, totalCompletedDays: 0)
    @Published private(set) var achievements: [Achievement] = []
    @Published private(set) var earnedBadgeIds: Set<Int> = []
    @Published var isCalendarExpanded = true
    @Published var displayedMonth: Date = .now

    private let service: BibleService
    private let persistence: AppPersistence
    private var didLoadOnce = false

    init(service: BibleService, persistence: AppPersistence) {
        self.service = service
        self.persistence = persistence
    }

    func loadIfNeeded() async {
        guard !didLoadOnce else { return }
        didLoadOnce = true
        await load()
    }

    var completedRecords: [DailyRecord] {
        records.filter(\.completed)
    }

    var weeklyRecords: [DailyRecord?] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today

        return (0..<7).map { offset in
            let day = calendar.date(byAdding: .day, value: offset, to: startOfWeek) ?? today
            return records.first(where: { calendar.isDate($0.verse.date, inSameDayAs: day) })
        }
    }

    func isBadgeEarned(_ achievement: Achievement) -> Bool {
        earnedBadgeIds.contains(achievement.id)
    }

    func load() async {
        do {
            async let history = service.fetchHistory()
            async let streak = service.fetchStreakSummary()
            async let badges = service.fetchBadgeDefinitions()
            async let earned = service.fetchUserEarnedBadgeIds()
            let loadedRecords = try await history
            summary = try await streak
            let fetched = (try? await badges) ?? []
            achievements = fetched.isEmpty ? BadgeIcons.fallbackCatalog : fetched
            earnedBadgeIds = (try? await earned) ?? []
            records = loadedRecords.map(applyCompletionState)
            recalculateSummary()
            syncWidgetData()
        } catch {
            records = []
            achievements = BadgeIcons.fallbackCatalog
        }
    }

    func toggleCalendarExpanded() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
            isCalendarExpanded.toggle()
        }
    }

    func shiftMonth(by delta: Int) {
        displayedMonth = Calendar.current.date(byAdding: .month, value: delta, to: displayedMonth) ?? displayedMonth
    }

    func record(for date: Date) -> DailyRecord? {
        records.first(where: { Calendar.current.isDate($0.verse.date, inSameDayAs: date) })
    }

    private func applyCompletionState(to record: DailyRecord) -> DailyRecord {
        let persisted = persistence.completedRecordIDs().contains(record.id)
        return DailyRecord(id: record.id, verse: record.verse, completed: record.completed || persisted)
    }

    private func recalculateSummary() {
        let completed = records.filter(\.completed)
        summary = StreakSummary(
            currentStreak: max(summary.currentStreak, currentCompletedStreak()),
            longestStreak: max(summary.longestStreak, currentCompletedStreak()),
            totalCompletedDays: completed.count
        )
    }

    private func currentCompletedStreak() -> Int {
        records
            .sorted { $0.verse.date > $1.verse.date }
            .prefix { $0.completed }
            .count
    }

    private func syncWidgetData() {
        syncStreakWidget()
        syncBadgeWidget()
    }

    private func syncStreakWidget() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        let symbols = ["S", "M", "T", "W", "T", "F", "S"]

        let weekDays: [SharedWeekDay] = (0..<7).map { offset in
            let day = calendar.date(byAdding: .day, value: offset, to: startOfWeek) ?? today
            let completed = records.contains { record in
                record.completed && calendar.isDate(record.verse.date, inSameDayAs: day)
            }
            let weekdayIndex = calendar.component(.weekday, from: day) - 1
            let symbol = symbols[weekdayIndex]
            return SharedWeekDay(symbol: symbol, isCompleted: completed)
        }

        WidgetDataStore.writeStreak(SharedStreakData(
            currentStreak: summary.currentStreak,
            longestStreak: summary.longestStreak,
            totalCompletedDays: summary.totalCompletedDays,
            weekDays: weekDays
        ))
        WidgetCenter.shared.reloadTimelines(ofKind: "StreakWidget")
    }

    private func syncBadgeWidget() {
        let earned = achievements
            .filter { earnedBadgeIds.contains($0.id) }
            .sorted { $0.weight < $1.weight }
            .map { badge in
                SharedBadgeEntry(
                    symbolName: badge.symbolName,
                    title: badge.name,
                    milestone: "\(badge.actionsRequired)d"
                )
            }

        WidgetDataStore.writeBadges(SharedBadgeData(badges: earned))
        WidgetCenter.shared.reloadTimelines(ofKind: "LockScreenIconWidget")
    }
}
