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
