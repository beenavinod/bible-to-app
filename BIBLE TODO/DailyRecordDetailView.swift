import SwiftUI

struct DailyRecordDetailView: View {
    @EnvironmentObject private var appState: AppState
    let record: DailyRecord

    var body: some View {
        ZStack {
            AppBackgroundView(background: appState.background)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    TopBar(
                        title: record.verse.title,
                        subtitle: record.verse.date.formatted(.dateTime.weekday(.wide).month(.wide).day()),
                        palette: appState.palette,
                        showsBackButton: true
                    )

                    CardContainer(palette: appState.palette) {
                        VStack(spacing: 16) {
                            Text("\"\(record.verse.text)\"")
                                .font(.system(.title3, design: .serif))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(appState.palette.primaryText)
                                .lineSpacing(6)

                            Text("— \(record.verse.reference)")
                                .font(.headline)
                                .foregroundStyle(appState.palette.secondaryText)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    }

                    CardContainer(palette: appState.palette) {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("TODAY'S ACTION")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(appState.palette.secondaryText)
                            Text(record.verse.taskTitle)
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(appState.palette.primaryText)
                            Text(record.verse.taskDescription)
                                .font(.subheadline)
                                .foregroundStyle(appState.palette.secondaryText)
                            Text(record.verse.taskQuote)
                                .font(.footnote.italic())
                                .foregroundStyle(appState.palette.secondaryText)
                            Label(record.completed ? "Completed" : "Not completed", systemImage: record.completed ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(record.completed ? appState.palette.accent : appState.palette.secondaryText)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
            .safeAreaPadding(.top, 12)
        }
    }
}
