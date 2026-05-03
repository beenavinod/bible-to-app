import SwiftUI

private let detailTaskAccent = Color(red: 0.16, green: 0.58, blue: 0.36)
private let detailTaskAccentSoft = Color(red: 0.16, green: 0.58, blue: 0.36).opacity(0.18)

struct DailyRecordDetailView: View {
    @EnvironmentObject private var appState: AppState
    let record: DailyRecord

    private var fg: HomeForegroundStyle {
        appState.homeWallpaper.homeForeground
    }

    private var isRecordToday: Bool {
        Calendar.current.isDate(record.verse.date, inSameDayAs: Date())
    }

    var body: some View {
        ZStack {
            HomeWallpaperBackgroundView(wallpaper: appState.homeWallpaper)

            ScrollView {
                VStack(spacing: 0) {
                    HomeDayVerseSection(record: record, fg: fg)
                    detailTaskCard
                        .padding(.top, 28)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle(record.verse.date.formatted(date: .abbreviated, time: .omitted))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    private var detailTaskCard: some View {
        HomeDayTaskCard(record: record, fg: fg, isViewingToday: isRecordToday) {
            Group {
                if record.completed {
                    HomePressHoldCircleView(
                        progress: 1,
                        isCompleted: true,
                        isInteractive: false,
                        primaryText: fg.primary,
                        secondaryText: fg.secondary,
                        accent: detailTaskAccent,
                        accentSoft: detailTaskAccentSoft,
                        onPress: {},
                        onRelease: {}
                    )
                } else {
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(fg.taskHoldTrackFill)
                                .frame(width: 108, height: 108)
                                .overlay(
                                    Circle()
                                        .stroke(fg.glassStroke, lineWidth: 1)
                                )
                            Image(systemName: "lock.fill")
                                .font(.system(size: 26, weight: .semibold))
                                .foregroundStyle(fg.taskCardSecondary)
                        }
                        Text("View only")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(fg.taskCardSecondary)
                    }
                }
            }
            .padding(.top, 2)
        }
    }
}
