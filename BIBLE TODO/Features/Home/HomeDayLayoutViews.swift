import SwiftUI

// MARK: - Shared home day layout (Home + Journey day detail + share export)

struct HomeDayVerseSection: View {
    let record: DailyRecord
    let fg: HomeForegroundStyle
    /// >1 for large export renders (e.g. share image).
    var fontScale: CGFloat = 1

    var body: some View {
        let verseSize = 22 * fontScale
        let refSize = 17 * fontScale

        VStack(spacing: 14 * fontScale) {
            Text("\"\(record.verse.text)\"")
                .font(.system(size: verseSize, weight: .regular, design: .serif))
                .multilineTextAlignment(.center)
                .foregroundStyle(fg.primary)
                .lineSpacing(6 * fontScale)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity)
                .shadow(color: fg.legibilityShadow, radius: 0, x: 0, y: 1)
                .shadow(color: fg.legibilityShadow.opacity(0.5), radius: 5 * fontScale, x: 0, y: 0)

            Text("— \(record.verse.reference)")
                .font(.system(size: refSize, weight: .semibold, design: .default))
                .foregroundStyle(fg.secondary)
                .shadow(color: fg.legibilityShadow, radius: 0, x: 0, y: 1)
                .shadow(color: fg.legibilityShadow.opacity(0.45), radius: 4 * fontScale, x: 0, y: 0)
        }
    }
}

private struct HomeDayTaskTitleBody: View {
    let record: DailyRecord
    let fg: HomeForegroundStyle
    let isViewingToday: Bool
    var fontScale: CGFloat = 1

    var body: some View {
        VStack(alignment: .leading, spacing: 8 * fontScale) {
            Text(record.verse.taskTitle)
                .font(.system(size: 17 * fontScale, weight: .semibold, design: .default))
                .foregroundStyle(fg.primary)
                .fixedSize(horizontal: false, vertical: true)

            Text(record.verse.taskDescription)
                .font(.system(size: 15 * fontScale, weight: .regular, design: .default))
                .foregroundStyle(fg.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if !record.verse.taskQuote.isEmpty {
                Text(record.verse.taskQuote)
                    .font(.system(size: 12 * fontScale, weight: .regular, design: .default))
                    .italic()
                    .foregroundStyle(fg.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !isViewingToday && !record.completed {
                Text("Past day — view only")
                    .font(.system(size: 12 * fontScale, weight: .regular, design: .default))
                    .foregroundStyle(fg.secondary)
                    .padding(.top, 2 * fontScale)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct HomeDayTaskCard<Trailing: View>: View {
    let record: DailyRecord
    let fg: HomeForegroundStyle
    let isViewingToday: Bool
    var fontScale: CGFloat = 1
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        let padH = 18 * fontScale
        let padV = 18 * fontScale
        let corner: CGFloat = 28 * fontScale

        HStack(alignment: .top, spacing: 16 * fontScale) {
            HomeDayTaskTitleBody(record: record, fg: fg, isViewingToday: isViewingToday, fontScale: fontScale)
            trailing()
        }
        .padding(.top, 2 * fontScale)
        .padding(.horizontal, padH)
        .padding(.vertical, padV)
        .background(
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(fg.taskCardFill)
                .shadow(color: fg.taskCardShadow, radius: 10 * fontScale, x: 0, y: 4 * fontScale)
        )
        .overlay(
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .stroke(fg.glassStroke.opacity(0.85), lineWidth: 1)
        )
    }
}

/// Same white task card as home, text only (for share image — no hold ring).
struct HomeDayTaskCardTextOnly: View {
    let record: DailyRecord
    let fg: HomeForegroundStyle
    var fontScale: CGFloat = 1
    var isViewingToday: Bool = true

    var body: some View {
        let padH = 18 * fontScale
        let padV = 18 * fontScale
        let corner: CGFloat = 28 * fontScale

        HomeDayTaskTitleBody(record: record, fg: fg, isViewingToday: isViewingToday, fontScale: fontScale)
            .padding(.top, 2 * fontScale)
            .padding(.horizontal, padH)
            .padding(.vertical, padV)
            .background(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(fg.taskCardFill)
                    .shadow(color: fg.taskCardShadow, radius: 10 * fontScale, x: 0, y: 4 * fontScale)
            )
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(fg.glassStroke.opacity(0.85), lineWidth: 1)
            )
    }
}
