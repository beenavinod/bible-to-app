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
    /// True until the first `loadIfNeeded` finishes (success or failure), or while a cancelled first load is waiting to retry.
    @Published private(set) var isLoadingInitialContent = true

    private let service: BibleService
    private let persistence: AppPersistence
    private let isPremiumUnlockedForWidgets: @MainActor () -> Bool
    private let onJourneyDataShouldRefresh: (() async -> Void)?
    private var historyCache: [DailyRecord] = []
    private var recordsByDay: [Date: DailyRecord] = [:]
    private var orderedDayStarts: [Date] = []
    private var completionTask: Task<Void, Never>?
    private var didLoadOnce = false

    init(
        service: BibleService,
        persistence: AppPersistence,
        isPremiumUnlockedForWidgets: @escaping @MainActor () -> Bool = { WidgetDataStore.readPremiumUnlocked() },
        onJourneyDataShouldRefresh: (() async -> Void)? = nil
    ) {
        self.service = service
        self.persistence = persistence
        self.isPremiumUnlockedForWidgets = isPremiumUnlockedForWidgets
        self.onJourneyDataShouldRefresh = onJourneyDataShouldRefresh
    }

    var isViewingToday: Bool { focusedDayIndex == 0 }

    func loadIfNeeded() async {
        guard !didLoadOnce else {
            isLoadingInitialContent = false
            return
        }
        await load()
    }

    func load() async {
        isLoadingInitialContent = true
        do {
            let today = try await service.fetchTodayDailyRecord()
            historyCache = (try? await service.fetchHistory()) ?? []
            rebuildDayMap(todayRecord: today)
            focusedDayIndex = min(focusedDayIndex, max(0, orderedDayStarts.count - 1))
            applyDisplayedRecord()
            updateNavigationFlags()
            let todayKey = Calendar.current.startOfDay(for: today.verse.date)
            if let record = recordsByDay[todayKey] {
                syncVerseTaskWidget(record: record)
            } else {
                syncVerseTaskWidget(record: applyCompletionState(to: today))
            }
            didLoadOnce = true
            isLoadingInitialContent = false
        } catch is CancellationError {
            isLoadingInitialContent = true
        } catch {
            #if DEBUG
            if let decoding = error as? DecodingError {
                print("HomeViewModel.load DecodingError: \(decoding.detailedDescription)")
            } else {
                print("HomeViewModel.load failed: \(error.localizedDescription)")
            }
            #endif
            recordsByDay = [:]
            orderedDayStarts = []
            displayedRecord = nil
            canGoToOlderDay = false
            canGoToNewerDay = false
            didLoadOnce = true
            isLoadingInitialContent = false
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

    private func rebuildDayMap(todayRecord: DailyRecord) {
        let cal = Calendar.current
        var map: [Date: DailyRecord] = [:]
        for r in historyCache {
            let d = cal.startOfDay(for: r.verse.date)
            map[d] = applyCompletionState(to: r)
        }
        let todayStart = cal.startOfDay(for: todayRecord.verse.date)
        /// `fetchTodayDailyRecord` already ran `loadDailyContent` (find-or-create). Use that row as source of truth so `DailyRecord.id` stays the real `user_tasks` id even when history omits today.
        map[todayStart] = applyCompletionState(to: todayRecord)
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
            await onJourneyDataShouldRefresh?()
        }
        syncVerseTaskWidget(record: completedRecord)
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

    private func syncVerseTaskWidget(record: DailyRecord) {
        let verse = record.verse
        let dateISO = BibleTodoDate.formatLocalDay(verse.date)
        let showTask = isPremiumUnlockedForWidgets()
        WidgetDataStore.writeVerseTask(SharedVerseTaskData(
            verseText: verse.text,
            reference: verse.reference,
            taskTitle: showTask ? verse.taskTitle : "",
            taskDescription: showTask ? verse.taskDescription : "",
            symbolName: verse.symbolName,
            dateISO: dateISO,
            taskCompleted: record.completed
        ))
        WidgetCenter.shared.reloadTimelines(ofKind: "VerseTaskWidget")
    }

    /// Re-writes widget payload when premium status changes (task text depends on subscription + App Group mirror).
    func resyncVerseWidgetForCurrentVerse() {
        guard let record = displayedRecord else { return }
        syncVerseTaskWidget(record: record)
    }
}

#if DEBUG
extension DecodingError {
    fileprivate var detailedDescription: String {
        switch self {
        case .keyNotFound(let key, let ctx):
            "keyNotFound(\(key.stringValue)) path=\(ctx.codingPath.map(\.stringValue).joined(separator: ".")) \(ctx.debugDescription)"
        case .typeMismatch(let type, let ctx):
            "typeMismatch(\(type)) path=\(ctx.codingPath.map(\.stringValue).joined(separator: ".")) \(ctx.debugDescription)"
        case .valueNotFound(let type, let ctx):
            "valueNotFound(\(type)) path=\(ctx.codingPath.map(\.stringValue).joined(separator: ".")) \(ctx.debugDescription)"
        case .dataCorrupted(let ctx):
            "dataCorrupted path=\(ctx.codingPath.map(\.stringValue).joined(separator: ".")) \(ctx.debugDescription)"
        @unknown default:
            String(describing: self)
        }
    }
}
#endif
