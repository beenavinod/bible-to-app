import Foundation
import Supabase

/// Supabase PostgREST operations for Bible TODO (see project-bible-todo spec 04).
final class BibleTodoRepository: Sendable {
    private let client: SupabaseClient

    init(client: SupabaseClient) {
        self.client = client
    }

    // MARK: - Launch & profile

    enum LaunchDestination: Equatable {
        case welcome
        case onboarding
        case home
    }

    /// Returns launch destination, user id when signed in, and the profile row when loaded (avoids a duplicate profile fetch during bootstrap).
    func resolveAppLaunchState() async throws -> (LaunchDestination, UUID?, ProfileRow?) {
        do {
            let session = try await client.auth.session
            let userId = session.user.id
            let profile: ProfileRow = try await client
                .from("profiles")
                .select("id, onboarding_completed, onboarding_data, created_at")
                .eq("id", value: userId)
                .single()
                .execute()
                .value
            let dest: LaunchDestination = profile.onboardingCompleted ? .home : .onboarding
            return (dest, userId, profile)
        } catch {
            return (.welcome, nil, nil)
        }
    }

    func fetchProfile(userId: UUID) async throws -> ProfileRow {
        try await client
            .from("profiles")
            .select()
            .eq("id", value: userId)
            .single()
            .execute()
            .value
    }

    func completeOnboarding(userId: UUID, payload: OnboardingRemotePayload) async throws {
        let body = ProfileOnboardingUpdate(onboarding_data: payload, onboarding_completed: true)
        try await client
            .from("profiles")
            .update(body)
            .eq("id", value: userId)
            .execute()
    }

    /// Inserts today's `user_tasks` row for the canonical first onboarding verse task as **completed**, and updates streaks.
    /// No-op if today already has a `user_tasks` row. Same `verse_task_id` for every user (see `FirstOnboardingTask`).
    func recordCanonicalFirstOnboardingTaskCompleted(userId: UUID) async throws {
        let today = BibleTodoDate.formatLocalDay(Date())
        if try await fetchExistingUserTask(userId: userId, date: today) != nil {
            return
        }
        let verseTaskId = try await fetchCanonicalFirstOnboardingVerseTaskId()
        let completedAt = Self.isoFormatter.string(from: Date())
        let insert = UserTaskInsert(
            userId: userId,
            verseTaskId: verseTaskId,
            assignedDate: today,
            status: "completed",
            completedAt: completedAt
        )
        try await client
            .from("user_tasks")
            .insert(insert)
            .execute()

        _ = try await updateStreak(userId: userId, completedDate: today)
    }

    private func fetchCanonicalFirstOnboardingVerseTaskId() async throws -> UUID {
        let rows: [VerseTaskCandidate] = try await client
            .from("verse_tasks")
            .select("""
                id, title, description, category,
                verses!inner(id, content)
                """)
            .eq("category", value: FirstOnboardingTask.categorySlug)
            .execute()
            .value

        let active = rows.filter(\.verses.content.isActive)
        let match = active.first { $0.verses.content.reference == FirstOnboardingTask.verseReference }
        guard let id = match?.id ?? active.min(by: { $0.verses.content.displayOrder < $1.verses.content.displayOrder })?.id else {
            throw BibleTodoRepositoryError.noVerseAvailable
        }
        return id
    }

    // MARK: - Daily content

    private func dailyCacheKey(userId: UUID) -> String {
        "daily_content_\(userId.uuidString)"
    }

    func getCachedDailyContent(userId: UUID) -> DailyContentCache? {
        let key = dailyCacheKey(userId: userId)
        guard let data = UserDefaults.standard.data(forKey: key),
              let cached = try? JSONDecoder().decode(DailyContentCache.self, from: data),
              cached.assignedDate == BibleTodoDate.formatLocalDay(Date())
        else {
            return nil
        }
        return cached
    }

    func cacheDailyContent(_ content: DailyContentCache, userId: UUID) {
        let key = dailyCacheKey(userId: userId)
        if let data = try? JSONEncoder().encode(content) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func clearDailyCache(userId: UUID) {
        UserDefaults.standard.removeObject(forKey: dailyCacheKey(userId: userId))
    }

    func fetchExistingUserTask(userId: UUID, date: String) async throws -> UserTaskWithDetails? {
        let results: [UserTaskWithDetails] = try await client
            .from("user_tasks")
            .select("""
                id, assigned_date, status, completed_at,
                verse_tasks(
                    id, title, description, category,
                    verses(id, content)
                )
                """)
            .eq("user_id", value: userId)
            .eq("assigned_date", value: date)
            .execute()
            .value
        return results.first
    }

    func assignNextVerse(userId: UUID, category: String, date: String) async throws -> DailyContentCache {
        let existingTasks: [ExistingTaskId] = try await client
            .from("user_tasks")
            .select("verse_task_id")
            .eq("user_id", value: userId)
            .execute()
            .value

        let used = Set(existingTasks.map(\.verseTaskId))

        let rawCandidates: [VerseTaskCandidate] = try await client
            .from("verse_tasks")
            .select("""
                id, title, description, category,
                verses!inner(id, content)
                """)
            .eq("category", value: category)
            .execute()
            .value

        let candidates = rawCandidates
            .filter { $0.verses.content.isActive }
            .sorted { $0.verses.content.displayOrder < $1.verses.content.displayOrder }

        let selected = candidates.first(where: { !used.contains($0.id) }) ?? candidates.first
        guard let verseTask = selected else {
            throw BibleTodoRepositoryError.noVerseAvailable
        }

        return try await createUserTask(userId: userId, verseTask: verseTask, date: date)
    }

    private func createUserTask(userId: UUID, verseTask: VerseTaskCandidate, date: String) async throws -> DailyContentCache {
        let insert = UserTaskInsert(
            userId: userId,
            verseTaskId: verseTask.id,
            assignedDate: date,
            status: "pending",
            completedAt: nil
        )

        let inserted: UserTaskWithDetails = try await client
            .from("user_tasks")
            .insert(insert)
            .select("""
                id, assigned_date, status, completed_at,
                verse_tasks(
                    id, title, description, category,
                    verses(id, content)
                )
                """)
            .single()
            .execute()
            .value

        return Self.mapToCache(inserted)
    }

    static func mapToCache(_ row: UserTaskWithDetails) -> DailyContentCache {
        let v = row.verseTasks.verses.content
        return DailyContentCache(
            userTaskId: row.id,
            assignedDate: row.assignedDate,
            status: row.status,
            completedAt: row.completedAt,
            verseId: row.verseTasks.verses.id,
            verseText: v.text,
            verseReference: v.reference,
            taskTitle: row.verseTasks.title,
            taskDescription: row.verseTasks.description,
            taskCategory: row.verseTasks.category
        )
    }

    func loadDailyContent(userId: UUID, category: String) async throws -> DailyContentCache {
        let today = BibleTodoDate.formatLocalDay(Date())

        if let cached = getCachedDailyContent(userId: userId) {
            return cached
        }

        if let existing = try await fetchExistingUserTask(userId: userId, date: today) {
            let cache = Self.mapToCache(existing)
            cacheDailyContent(cache, userId: userId)
            return cache
        }

        let created = try await assignNextVerse(userId: userId, category: category, date: today)
        cacheDailyContent(created, userId: userId)
        return created
    }

    // MARK: - Complete / undo

    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    func completeTask(userId: UUID, userTaskId: UUID, date: String) async throws -> StreakInfo {
        let completedAt = Self.isoFormatter.string(from: Date())
        let completedPatch: JSONObject = [
            "status": .string("completed"),
            "completed_at": .string(completedAt)
        ]
        try await client
            .from("user_tasks")
            .update(completedPatch)
            .eq("id", value: userTaskId)
            .eq("user_id", value: userId)
            .execute()

        let info = try await updateStreak(userId: userId, completedDate: date)

        if var cached = getCachedDailyContent(userId: userId), cached.userTaskId == userTaskId {
            cached.status = "completed"
            cached.completedAt = completedAt
            cacheDailyContent(cached, userId: userId)
        }

        return info
    }

    func updateStreak(userId: UUID, completedDate: String) async throws -> StreakInfo {
        let streak: UserStreakRow = try await client
            .from("user_streaks")
            .select()
            .eq("user_id", value: userId)
            .single()
            .execute()
            .value

        let today = completedDate
        guard let yesterdayDate = Calendar.current.date(byAdding: .day, value: -1, to: Date()) else {
            throw BibleTodoRepositoryError.invalidConfiguration
        }
        let yesterday = BibleTodoDate.formatLocalDay(yesterdayDate)

        if streak.lastCompletedDate == today {
            return StreakInfo(
                currentStreak: streak.currentStreak,
                longestStreak: streak.longestStreak,
                isNewMilestone: false
            )
        }

        let newCurrent: Int
        if streak.lastCompletedDate == yesterday {
            newCurrent = streak.currentStreak + 1
        } else {
            newCurrent = 1
        }
        let newLongest = max(streak.longestStreak, newCurrent)
        let milestone = [7, 30, 60, 100, 365].contains(newCurrent)

        let streakPatch: JSONObject = [
            "current_streak": .integer(newCurrent),
            "longest_streak": .integer(newLongest),
            "last_completed_date": .string(today)
        ]
        try await client
            .from("user_streaks")
            .update(streakPatch)
            .eq("user_id", value: userId)
            .execute()

        return StreakInfo(currentStreak: newCurrent, longestStreak: newLongest, isNewMilestone: milestone)
    }

    func undoTaskCompletion(userId: UUID, userTaskId: UUID, date: String) async throws {
        let pendingPatch: JSONObject = [
            "status": .string("pending"),
            "completed_at": .null
        ]
        try await client
            .from("user_tasks")
            .update(pendingPatch)
            .eq("id", value: userTaskId)
            .eq("user_id", value: userId)
            .execute()

        let previousRows: [AssignedDateOnly] = try await client
            .from("user_tasks")
            .select("assigned_date")
            .eq("user_id", value: userId)
            .eq("status", value: "completed")
            .neq("assigned_date", value: date)
            .order("assigned_date", ascending: false)
            .limit(1)
            .execute()
            .value

        let lastDate = previousRows.first?.assignedDate

        if lastDate == nil {
            let resetPatch: JSONObject = [
                "current_streak": .integer(0),
                "last_completed_date": .null
            ]
            try await client
                .from("user_streaks")
                .update(resetPatch)
                .eq("user_id", value: userId)
                .execute()
        } else {
            let chain: [AssignedDateOnly] = try await client
                .from("user_tasks")
                .select("assigned_date")
                .eq("user_id", value: userId)
                .eq("status", value: "completed")
                .lte("assigned_date", value: lastDate!)
                .order("assigned_date", ascending: false)
                .limit(365)
                .execute()
                .value

            let streakCount = Self.countConsecutiveDaysBackward(from: lastDate!, sortedDescendingDates: chain.map(\.assignedDate))
            let undoStreakPatch: JSONObject = [
                "current_streak": .integer(streakCount),
                "last_completed_date": .string(lastDate!)
            ]
            try await client
                .from("user_streaks")
                .update(undoStreakPatch)
                .eq("user_id", value: userId)
                .execute()
        }

        if var cached = getCachedDailyContent(userId: userId), cached.userTaskId == userTaskId {
            cached.status = "pending"
            cached.completedAt = nil
            cacheDailyContent(cached, userId: userId)
        }
    }

    private static func countConsecutiveDaysBackward(from anchor: String, sortedDescendingDates: [String]) -> Int {
        guard let anchorDate = BibleTodoDate.parseLocalDay(anchor) else { return 0 }
        var expected = anchorDate
        var count = 0
        let cal = Calendar.current
        for day in sortedDescendingDates {
            guard let d = BibleTodoDate.parseLocalDay(day) else { continue }
            if cal.isDate(d, inSameDayAs: expected) {
                count += 1
                expected = cal.date(byAdding: .day, value: -1, to: expected) ?? expected
            } else if d < expected {
                break
            }
        }
        return count
    }

    // MARK: - History & stats

    func fetchHistory(userId: UUID, limit: Int = 60, offset: Int = 0) async throws -> [UserTaskWithDetails] {
        try await client
            .from("user_tasks")
            .select("""
                id, assigned_date, status, completed_at,
                verse_tasks(
                    id, title, description, category,
                    verses(id, content)
                )
                """)
            .eq("user_id", value: userId)
            .order("assigned_date", ascending: false)
            .range(from: offset, to: offset + max(limit - 1, 0))
            .execute()
            .value
    }

    func fetchStreakSummary(userId: UUID) async throws -> StreakSummary {
        let row: UserStreakRow = try await client
            .from("user_streaks")
            .select()
            .eq("user_id", value: userId)
            .single()
            .execute()
            .value

        let countResponse = try await client
            .from("user_tasks")
            .select("*", head: true, count: .exact)
            .eq("user_id", value: userId)
            .eq("status", value: "completed")
            .execute()
        let total = countResponse.count ?? 0

        return StreakSummary(
            currentStreak: row.currentStreak,
            longestStreak: row.longestStreak,
            totalCompletedDays: total
        )
    }
}
