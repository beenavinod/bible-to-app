import SwiftUI

struct JourneyView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var viewModel: JourneyViewModel
    @State private var sharePayload: ShareDrawerPayload?

    init(viewModel: JourneyViewModel) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView(background: appState.background)

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        TopBar(
                            title: "Journey History",
                            subtitle: nil,
                            palette: appState.palette,
                            onShareTap: {
                                sharePayload = .streak(viewModel.summary, week: viewModel.weeklyRecords)
                            }
                        )

                        streakCard
                        calendarCard
                        achievementsCard
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
        .sheet(item: $sharePayload) { payload in
            ShareDrawerSheet(payload: payload, palette: appState.palette)
                .presentationDetents([.height(520), .large])
                .presentationDragIndicator(.visible)
        }
    }

    private var streakCard: some View {
        CardContainer(palette: appState.palette) {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    statItem(title: "Current Streak", value: "\(viewModel.summary.currentStreak)", icon: "flame.fill")
                    Spacer()
                    statText(title: "Longest", value: "\(viewModel.summary.longestStreak)")
                }

                statText(title: "Total Days Completed", value: "\(viewModel.summary.totalCompletedDays)", centered: true)

                Divider()
                    .overlay(appState.palette.border)

                VStack(alignment: .leading, spacing: 16) {
                    Text("THIS WEEK")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(appState.palette.primaryText)

                    WeekProgressView(records: viewModel.weeklyRecords, palette: appState.palette)

                    Button(viewModel.isCalendarExpanded ? "Hide Calendar" : "View Full Calendar") {
                        viewModel.toggleCalendarExpanded()
                    }
                    .font(.subheadline)
                    .foregroundStyle(appState.palette.accent)
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private var calendarCard: some View {
        Group {
            if viewModel.isCalendarExpanded {
                CardContainer(palette: appState.palette) {
                    CalendarSectionView(
                        month: viewModel.displayedMonth,
                        records: viewModel.completedRecords,
                        palette: appState.palette,
                        onPrevious: { viewModel.shiftMonth(by: -1) },
                        onNext: { viewModel.shiftMonth(by: 1) }
                    )
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    private var achievementsCard: some View {
        CardContainer(palette: appState.palette) {
            VStack(alignment: .leading, spacing: 16) {
                Text("ACHIEVEMENT ICONS")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(appState.palette.primaryText)

                Text("Unlock spiritual icons as you build your streak. Add them to your home screen.")
                    .font(.subheadline)
                    .foregroundStyle(appState.palette.secondaryText)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14, alignment: .top), count: 4), spacing: 18) {
                    ForEach(viewModel.achievements) { achievement in
                        AchievementBadgeView(
                            achievement: achievement,
                            unlocked: achievement.isUnlocked(for: viewModel.summary.currentStreak),
                            palette: appState.palette
                        )
                    }
                }
            }
        }
    }

    private func statItem(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(appState.palette.headerAccent.opacity(0.85))
                .frame(width: 42, height: 42)
                .overlay {
                    Image(systemName: icon)
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(appState.palette.secondaryText)
                Text(value)
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                    .foregroundStyle(appState.palette.primaryText)
            }
        }
    }

    private func statText(title: String, value: String, centered: Bool = false) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(appState.palette.secondaryText)
            Text(value)
                .font(.title.weight(.semibold))
                .foregroundStyle(appState.palette.primaryText)
        }
        .frame(maxWidth: .infinity, alignment: centered ? .center : .trailing)
    }
}
