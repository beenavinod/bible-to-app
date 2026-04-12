import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var viewModel: HomeViewModel
    @State private var sharePayload: ShareDrawerPayload?

    init(viewModel: HomeViewModel) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView(background: appState.background)

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        TopBar(
                            title: "Daily Verse",
                            subtitle: viewModel.todayRecord?.verse.date.formatted(.dateTime.weekday(.wide).month(.wide).day()) ?? Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()),
                            palette: appState.palette,
                            showsBackButton: true,
                            onShareTap: shareAction
                        )

                        if let record = viewModel.todayRecord {
                            verseCard(record: record)
                            taskCard(record: record)
                        } else {
                            EmptyStateView(
                                title: "Unable to load today’s verse",
                                subtitle: "Check your network, confirm Supabase URL and key in Info.plist, and try again.",
                                palette: appState.palette
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 110)
                }
                .safeAreaPadding(.top, 12)
            }
        }
        .task {
            await viewModel.loadIfNeeded()
        }
        .sensoryFeedback(.success, trigger: viewModel.didCompleteTask)
        .sheet(item: $sharePayload) { payload in
            ShareDrawerSheet(payload: payload, palette: appState.palette)
                .presentationDetents([.height(520), .large])
                .presentationDragIndicator(.visible)
        }
    }

    private var shareAction: (() -> Void)? {
        guard let record = viewModel.todayRecord else { return nil }
        return { sharePayload = .verse(record) }
    }

    private func verseCard(record: DailyRecord) -> some View {
        CardContainer(palette: appState.palette) {
            VStack(spacing: 16) {
                Spacer(minLength: 12)

                Text("\"\(record.verse.text)\"")
                    .font(.system(.title3, design: .serif))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(appState.palette.primaryText)
                    .lineSpacing(6)
                    .minimumScaleFactor(0.85)

                Text("— \(record.verse.reference)")
                    .font(.headline)
                    .foregroundStyle(appState.palette.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
        }
    }

    private func taskCard(record: DailyRecord) -> some View {
        CardContainer(palette: appState.palette) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 12) {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(appState.palette.canvas)
                        .frame(width: 52, height: 52)
                        .overlay {
                            Image(systemName: record.verse.symbolName)
                                .font(.title2)
                                .foregroundStyle(appState.palette.accent)
                        }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("TODAY'S ACTION")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(appState.palette.secondaryText)
                        Text(record.verse.taskTitle)
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(appState.palette.primaryText)
                        Text(record.verse.taskDescription)
                            .font(.subheadline)
                            .foregroundStyle(appState.palette.secondaryText)
                    }
                }

                Text(record.verse.taskQuote)
                    .font(.footnote.italic())
                    .foregroundStyle(appState.palette.secondaryText)

                VStack(spacing: 14) {
                    HoldToCompleteButton(
                        progress: viewModel.holdProgress,
                        palette: appState.palette,
                        isCompleted: record.completed,
                        onPress: viewModel.startHold,
                        onRelease: viewModel.cancelHold
                    )

                    Text(record.completed ? "Completed for today" : "Press and hold to complete")
                        .font(.subheadline)
                        .foregroundStyle(appState.palette.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 6)
            }
        }
    }
}

#Preview {
    AppStatePreviewRoot { appState in
        HomeView(viewModel: appState.mainTabViewModels!.home)
    }
}
