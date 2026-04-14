import SwiftUI

struct CalendarSectionView: View {
    let month: Date
    let records: [DailyRecord]
    let palette: AppThemePalette
    let onPrevious: () -> Void
    let onNext: () -> Void

    private let calendar = Calendar.current
    private let weekdaySymbols = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Button(action: onPrevious) {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(palette.secondaryText)
                }
                .buttonStyle(.plain)

                Spacer()

                Text(monthLabel)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.primaryText)

                Spacer()

                Button(action: onNext) {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(palette.secondaryText)
                }
                .buttonStyle(.plain)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 14) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption)
                        .foregroundStyle(palette.secondaryText)
                }

                ForEach(days, id: \.self) { date in
                    if let date {
                        if let record = records.first(where: { calendar.isDate($0.verse.date, inSameDayAs: date) }), record.completed {
                            NavigationLink {
                                DailyRecordDetailView(record: record)
                            } label: {
                                calendarCell(text: dayNumber(for: date), isCompleted: true)
                            }
                            .buttonStyle(.plain)
                        } else {
                            calendarCell(text: dayNumber(for: date), isCompleted: false)
                        }
                    } else {
                        Color.clear
                            .frame(height: 34)
                    }
                }
            }
        }
    }

    private var monthLabel: String {
        month.formatted(.dateTime.month(.wide).year())
    }

    private var days: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: month) else { return [] }
        let firstWeekday = calendar.component(.weekday, from: monthInterval.start) - 1
        let totalDays = calendar.range(of: .day, in: .month, for: monthInterval.start)?.count ?? 0

        var values = Array(repeating: Optional<Date>.none, count: firstWeekday)
        values += (1...totalDays).map { day in
            calendar.date(byAdding: .day, value: day - 1, to: monthInterval.start)
        }
        return values
    }

    private func dayNumber(for date: Date) -> String {
        String(calendar.component(.day, from: date))
    }

    private func calendarCell(text: String, isCompleted: Bool) -> some View {
        Text(text)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(isCompleted ? .white : palette.primaryText)
            .frame(maxWidth: .infinity)
            .frame(height: 34)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isCompleted ? palette.accent.opacity(0.9) : .clear)
            )
    }
}
