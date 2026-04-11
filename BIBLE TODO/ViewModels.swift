import Foundation
import Combine
import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var todayRecord: DailyRecord?
    @Published var holdProgress: Double = 0
    @Published private(set) var isCompleting = false
    @Published private(set) var didCompleteTask = false

    private let service: BibleService
    private let persistence: AppPersistence
    private var historyCache: [DailyRecord] = []
    private var completionTask: Task<Void, Never>?

    init(service: BibleService, persistence: AppPersistence) {
        self.service = service
        self.persistence = persistence
    }

    func load() async {
        do {
            async let todayVerse = service.fetchTodayVerse()
            async let history = service.fetchHistory()
            let verse = try await todayVerse
            historyCache = try await history

            if let matched = historyCache.first(where: { Calendar.current.isDate($0.verse.date, inSameDayAs: verse.date) }) {
                todayRecord = applyCompletionState(to: matched)
            } else {
                todayRecord = DailyRecord(id: UUID(), verse: verse, completed: false)
            }
        } catch {
            todayRecord = nil
        }
    }

    func startHold() {
        guard !isCompleting, todayRecord?.completed == false else { return }

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

    private func completeTodayTask() {
        completionTask?.cancel()
        completionTask = nil

        guard let record = todayRecord else { return }
        let completedRecord = DailyRecord(id: record.id, verse: record.verse, completed: true)

        updateCompletedState(for: completedRecord.id)
        todayRecord = completedRecord
        isCompleting = false
        didCompleteTask.toggle()

        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            holdProgress = 1
        }
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
}

@MainActor
final class JourneyViewModel: ObservableObject {
    @Published private(set) var records: [DailyRecord] = []
    @Published private(set) var summary = StreakSummary(currentStreak: 0, longestStreak: 0, totalCompletedDays: 0)
    @Published var isCalendarExpanded = true
    @Published var displayedMonth: Date = .now

    private let service: BibleService
    private let persistence: AppPersistence

    init(service: BibleService, persistence: AppPersistence) {
        self.service = service
        self.persistence = persistence
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

    var achievements: [Achievement] {
        Achievement.defaults
    }

    func load() async {
        do {
            async let history = service.fetchHistory()
            async let streak = service.fetchStreakSummary()
            let loadedRecords = try await history
            summary = try await streak
            records = loadedRecords.map(applyCompletionState)
            recalculateSummary()
        } catch {
            records = []
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
}
