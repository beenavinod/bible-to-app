import Foundation
import Combine
import SwiftUI
import WidgetKit

@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var displayedRecord: DailyRecord?
    @Published private(set) var focusedDayIndex: Int = 0
    @Published var holdProgress: Double = 0
    @Published private(set) var isCompleting = false
    @Published private(set) var didCompleteTask = false
    @Published private(set) var canGoToOlderDay = false
    @Published private(set) var canGoToNewerDay = false

    private let service: BibleService
    private let persistence: AppPersistence
    private var historyCache: [DailyRecord] = []
    private var recordsByDay: [Date: DailyRecord] = [:]
    private var orderedDayStarts: [Date] = []
    private var completionTask: Task<Void, Never>?
    private var didLoadOnce = false

    init(service: BibleService, persistence: AppPersistence) {
        self.service = service
        self.persistence = persistence
    }

    var isViewingToday: Bool { focusedDayIndex == 0 }

    func loadIfNeeded() async {
        guard !didLoadOnce else { return }
        didLoadOnce = true
        await load()
    }

    func load() async {
        do {
            async let todayVerse = service.fetchTodayVerse()
            async let history = service.fetchHistory()
            let verse = try await todayVerse
            historyCache = try await history
            rebuildDayMap(todayVerse: verse)
            focusedDayIndex = min(focusedDayIndex, max(0, orderedDayStarts.count - 1))
            applyDisplayedRecord()
            updateNavigationFlags()
            syncVerseTaskWidget(verse: verse)
        } catch {
            recordsByDay = [:]
            orderedDayStarts = []
            displayedRecord = nil
            canGoToOlderDay = false
            canGoToNewerDay = false
        }
    }

    func goToOlderDay() {
        guard canGoToOlderDay else { return }
        cancelHold()
        holdProgress = 0
        focusedDayIndex += 1
        applyDisplayedRecord()
        updateNavigationFlags()
    }

    func goToNewerDay() {
        guard canGoToNewerDay else { return }
        cancelHold()
        holdProgress = 0
        focusedDayIndex -= 1
        applyDisplayedRecord()
        updateNavigationFlags()
    }

    func goToToday() {
        cancelHold()
        holdProgress = 0
        focusedDayIndex = 0
        applyDisplayedRecord()
        updateNavigationFlags()
    }

    func startHold() {
        guard isViewingToday, let record = displayedRecord, !record.completed, !isCompleting else { return }

        completionTask?.cancel()
        isCompleting = true
        didCompleteTask = false
        holdProgress = 0

        completionTask = Task { [weak self] in
            guard let self else { return }

            let steps = 30
            for step in 1...steps {
                try? await Task.sleep(for: .milliseconds(80))
                if Task.isCancelled { return }
                holdProgress = Double(step) / Double(steps)
            }

            completeTodayTask()
        }
    }

    func cancelHold() {
        completionTask?.cancel()
        completionTask = nil
        guard isCompleting else { return }
        isCompleting = false
        withAnimation(.easeOut(duration: 0.2)) {
            holdProgress = 0
        }
    }

    private func rebuildDayMap(todayVerse: Verse) {
        let cal = Calendar.current
        var map: [Date: DailyRecord] = [:]
        for r in historyCache {
            let d = cal.startOfDay(for: r.verse.date)
            map[d] = applyCompletionState(to: r)
        }
        let todayStart = cal.startOfDay(for: todayVerse.date)
        if let matched = historyCache.first(where: { cal.isDate($0.verse.date, inSameDayAs: todayVerse.date) }) {
            map[todayStart] = applyCompletionState(to: matched)
        } else {
            let synthetic = DailyRecord(id: UUID(), verse: todayVerse, completed: false)
            map[todayStart] = applyCompletionState(to: synthetic)
        }
        recordsByDay = map
        orderedDayStarts = map.keys.sorted(by: >)
    }

    private func applyDisplayedRecord() {
        guard focusedDayIndex < orderedDayStarts.count else {
            displayedRecord = nil
            return
        }
        let key = orderedDayStarts[focusedDayIndex]
        displayedRecord = recordsByDay[key]
    }

    private func updateNavigationFlags() {
        canGoToOlderDay = focusedDayIndex + 1 < orderedDayStarts.count
        canGoToNewerDay = focusedDayIndex > 0
    }

    private func completeTodayTask() {
        completionTask?.cancel()
        completionTask = nil

        guard let record = displayedRecord, isViewingToday else { return }
        let completedRecord = DailyRecord(id: record.id, verse: record.verse, completed: true)

        updateCompletedState(for: completedRecord.id)

        let cal = Calendar.current
        let dayStart = cal.startOfDay(for: record.verse.date)
        recordsByDay[dayStart] = completedRecord
        displayedRecord = completedRecord

        isCompleting = false
        didCompleteTask.toggle()

        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            holdProgress = 1
        }

        let dateISO = BibleTodoDate.formatLocalDay(record.verse.date)
        Task {
            try? await service.syncTaskCompletion(
                userTaskId: record.id,
                assignedDateISO: dateISO,
                completed: true
            )
        }
        WidgetCenter.shared.reloadTimelines(ofKind: "VerseTaskWidget")
    }

    private func updateCompletedState(for id: UUID) {
        var ids = persistence.completedRecordIDs()
        ids.insert(id)
        persistence.setCompletedRecordIDs(ids)
    }

    private func applyCompletionState(to record: DailyRecord) -> DailyRecord {
        let isCompleted = record.completed || persistence.completedRecordIDs().contains(record.id)
        return DailyRecord(id: record.id, verse: record.verse, completed: isCompleted)
    }

    private func syncVerseTaskWidget(verse: Verse) {
        let dateISO = BibleTodoDate.formatLocalDay(verse.date)
        WidgetDataStore.writeVerseTask(SharedVerseTaskData(
            verseText: verse.text,
            reference: verse.reference,
            taskTitle: verse.taskTitle,
            taskDescription: verse.taskDescription,
            symbolName: verse.symbolName,
            dateISO: dateISO
        ))
        WidgetCenter.shared.reloadTimelines(ofKind: "VerseTaskWidget")
    }
}

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

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published private(set) var selectedTheme: AppTheme
    @Published private(set) var selectedBackground: AppBackground
    @Published private(set) var widgetsEnabled: Bool

    let themes = AppTheme.allCases
    let backgrounds = AppBackground.allCases

    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
        selectedTheme = appState.theme
        selectedBackground = appState.background
        widgetsEnabled = appState.widgetsEnabled
    }

    func setTheme(_ theme: AppTheme) {
        selectedTheme = theme
        appState.setTheme(theme)
    }

    func setBackground(_ background: AppBackground) {
        selectedBackground = background
        appState.setBackground(background)
    }

    func setWidgetsEnabled(_ isEnabled: Bool) {
        widgetsEnabled = isEnabled
        appState.setWidgetsEnabled(isEnabled)
    }

    func signOut() async {
        await appState.signOut()
    }
}
