import Foundation

enum BibleTodoDate {
    private static let calendar = Calendar.current

    /// Local calendar date as `YYYY-MM-DD` for `user_tasks.assigned_date`.
    static func formatLocalDay(_ date: Date) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        let y = c.year ?? 0
        let m = c.month ?? 0
        let d = c.day ?? 0
        return String(format: "%04d-%02d-%02d", y, m, d)
    }

    static func parseLocalDay(_ string: String) -> Date? {
        let parts = string.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        var c = DateComponents()
        c.year = parts[0]
        c.month = parts[1]
        c.day = parts[2]
        return calendar.date(from: c).map { calendar.startOfDay(for: $0) }
    }
}
