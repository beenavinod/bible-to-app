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
    /// Achievement id used for the Lock Screen accessory widget (`nil` until the user picks one).
    @Published private(set) var lockScreenWidgetBadgeId: Int?
    @Published var isCalendarExpanded = true
    @Published var displayedMonth: Date = .now

    private let service: BibleService
    private let persistence: AppPersistence
    private var didLoadOnce = false
    /// Server-backed definitions (positive ids). Used for the lock-screen widget so we do not depend on the fallback catalog’s negative test ids.
    private var serverBadgeDefinitions: [Achievement] = []

    init(service: BibleService, persistence: AppPersistence) {
        self.service = service
        self.persistence = persistence
        lockScreenWidgetBadgeId = persistence.lockScreenWidgetBadgeId()
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

    /// Persists the badge shown on the Lock Screen widget (must be earned). Pass `nil` to clear.
    func setLockScreenWidgetBadgeId(_ id: Int?) {
        if let id, !earnedBadgeIds.contains(id) { return }
        persistence.setLockScreenWidgetBadgeId(id)
        lockScreenWidgetBadgeId = id
        syncBadgeWidget()
    }

    private func reconcileLockScreenBadgeSelection() {
        guard let id = lockScreenWidgetBadgeId else { return }
        guard earnedBadgeIds.contains(id) else {
            persistence.setLockScreenWidgetBadgeId(nil)
            lockScreenWidgetBadgeId = nil
            return
        }
    }

    func load() async {
        do {
            async let history = service.fetchHistory()
            async let streak = service.fetchStreakSummary()
            async let badges = service.fetchBadgeDefinitions()
            async let earned = service.fetchUserEarnedBadgeIds()
            let loadedRecords = try await history
            summary = try await streak
            var fetched = (try? await badges) ?? []
            earnedBadgeIds = (try? await earned) ?? []
            if let wid = lockScreenWidgetBadgeId,
               earnedBadgeIds.contains(wid),
               !fetched.contains(where: { $0.id == wid }),
               let recovered = try? await service.fetchBadgeDefinition(id: wid) {
                fetched.append(recovered)
            }
            serverBadgeDefinitions = fetched
            achievements = fetched.isEmpty ? BadgeIcons.fallbackCatalog : fetched
            records = loadedRecords.map(applyCompletionState)
            recalculateSummary()
            reconcileLockScreenBadgeSelection()
            syncWidgetData()
        } catch {
            if records.isEmpty {
                records = []
                achievements = BadgeIcons.fallbackCatalog
                serverBadgeDefinitions = []
            }
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
        let localStreak = StreakCalculation.consecutiveCompletedDayStreak(records: records)
        summary = StreakSummary(
            currentStreak: localStreak,
            longestStreak: max(summary.longestStreak, localStreak),
            totalCompletedDays: completed.count
        )
    }

    /// Counts consecutive completed calendar days ending at today (or yesterday).
    /// Returns 0 if neither today nor yesterday is completed.
    private func currentCompletedStreak() -> Int {
        let calendar = Calendar.current
        let completedDates: Set<DateComponents> = Set(
            records
                .filter(\.completed)
                .map { calendar.dateComponents([.year, .month, .day], from: $0.verse.date) }
        )

        let today = calendar.startOfDay(for: .now)
        let todayComponents = calendar.dateComponents([.year, .month, .day], from: today)

        var anchor: Date
        if completedDates.contains(todayComponents) {
            anchor = today
        } else if let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
                  completedDates.contains(calendar.dateComponents([.year, .month, .day], from: yesterday)) {
            anchor = yesterday
        } else {
            return 0
        }

        var count = 0
        while true {
            let components = calendar.dateComponents([.year, .month, .day], from: anchor)
            guard completedDates.contains(components) else { break }
            count += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: anchor) else { break }
            anchor = previousDay
        }
        return count
    }

    private func syncWidgetData() {
        syncStreakWidget()
        syncBadgeWidget()
    }

    private func syncStreakWidget() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        /// Latest five calendar days ending today (oldest → newest). Labels use **day-of-month** so the row reads as actual dates, not a Sun–Sat week strip.
        let weekDays: [SharedWeekDay] = (0..<5).map { index in
            let dayOffset = index - 4
            let day = calendar.date(byAdding: .day, value: dayOffset, to: today) ?? today
            let completed = records.contains { record in
                record.completed && calendar.isDate(record.verse.date, inSameDayAs: day)
            }
            let label = day.formatted(.dateTime.day(.defaultDigits))
            return SharedWeekDay(symbol: label, isCompleted: completed)
        }

        /// Current locale week (7 days), same window as `weeklyRecords` / share card “THIS WEEK”.
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        let weekdaySymbols = calendar.shortWeekdaySymbols
        let calendarWeek: [SharedWeekDay] = (0..<7).map { offset in
            let day = calendar.date(byAdding: .day, value: offset, to: startOfWeek) ?? today
            let completed = records.contains { record in
                record.completed && calendar.isDate(record.verse.date, inSameDayAs: day)
            }
            let wdIndex = calendar.component(.weekday, from: day) - 1
            let label: String
            if weekdaySymbols.indices.contains(wdIndex) {
                label = String(weekdaySymbols[wdIndex].prefix(1))
            } else {
                label = "?"
            }
            return SharedWeekDay(symbol: label, isCompleted: completed)
        }

        WidgetDataStore.writeStreak(SharedStreakData(
            currentStreak: summary.currentStreak,
            longestStreak: summary.longestStreak,
            totalCompletedDays: summary.totalCompletedDays,
            weekDays: weekDays,
            calendarWeek: calendarWeek
        ))
        WidgetCenter.shared.reloadTimelines(ofKind: "StreakWidget")
    }

    private func syncBadgeWidget() {
        let entries: [SharedBadgeEntry]
        if let id = lockScreenWidgetBadgeId,
           earnedBadgeIds.contains(id),
           let badge = serverBadgeDefinitions.first(where: { $0.id == id })
               ?? achievements.first(where: { $0.id == id }) {
            entries = [
                SharedBadgeEntry(
                    symbolName: badge.symbolName,
                    title: badge.name,
                    milestone: Self.widgetMilestoneLabel(for: badge)
                )
            ]
        } else {
            entries = []
        }

        WidgetDataStore.writeBadges(SharedBadgeData(badges: entries))
        WidgetCenter.shared.reloadTimelines(ofKind: "LockScreenIconWidget")
    }

    private static func widgetMilestoneLabel(for achievement: Achievement) -> String {
        switch achievement.type {
        case .taskStreak:
            "\(achievement.actionsRequired)d"
        case .verseShare:
            "\(achievement.actionsRequired)×"
        case .firstShare:
            "1st"
        }
    }
}
