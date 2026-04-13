import SwiftUI

private struct HomeScrollMinYPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private let taskAccentGreen = Color(red: 0.16, green: 0.58, blue: 0.36)
private let taskAccentGreenSoft = Color(red: 0.16, green: 0.58, blue: 0.36).opacity(0.18)

struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var viewModel: HomeViewModel
    @Binding var path: NavigationPath

    @State private var sharePayload: ShareDrawerPayload?
    @State private var showBibleReader = false
    @State private var showHomeBackgroundPicker = false
    @State private var didTriggerPullPreviousDay = false

    init(viewModel: HomeViewModel, path: Binding<NavigationPath>) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
        _path = path
    }

    private var fg: HomeForegroundStyle {
        appState.homeWallpaper.homeForeground
    }

    var body: some View {
        ZStack {
            HomeWallpaperBackgroundView(wallpaper: appState.homeWallpaper)

            GeometryReader { geo in
                let safeTop = geo.safeAreaInsets.top
                let safeBottom = geo.safeAreaInsets.bottom
                let topChromeH: CGFloat = 56
                let bottomIconsH: CGFloat = 56
                let topInset = safeTop + topChromeH + 6
                let bottomScrollPadding = bottomIconsH + safeBottom + 20
                /// Room for compact task card under centered verse.
                let taskCompact: CGFloat = 148
                let verseMinH = max(
                    100,
                    geo.size.height - topInset - bottomScrollPadding - taskCompact - 16
                )

                ZStack(alignment: .top) {
                    ScrollView {
                        VStack(spacing: 0) {
                            Color.clear
                                .frame(height: 0)
                                .background(scrollOffsetReader)

                            VStack {
                                Spacer(minLength: 0)
                                if let record = viewModel.displayedRecord {
                                    verseSection(record: record)
                                } else {
                                    homeEmptyState
                                }
                                Spacer(minLength: 0)
                            }
                            .frame(minHeight: verseMinH)

                            if let record = viewModel.displayedRecord {
                                taskSection(record: record)
                                    .padding(.top, 16)
                            }

                            Color.clear
                                .frame(height: bottomScrollPadding)
                        }
                        .padding(.horizontal, 22)
                        .padding(.top, topInset)
                    }
                    .scrollIndicators(.hidden)
                    .coordinateSpace(name: "homeScroll")
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .onPreferenceChange(HomeScrollMinYPreferenceKey.self) { minY in
                        if minY > 56 {
                            if !didTriggerPullPreviousDay, viewModel.canGoToOlderDay {
                                didTriggerPullPreviousDay = true
                                viewModel.goToOlderDay()
                            }
                        } else if minY < 12 {
                            didTriggerPullPreviousDay = false
                        }
                    }

                    topChromeRow
                        .padding(.top, safeTop + 4)
                }
                .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
                .overlay(alignment: .bottom) {
                    bottomChromeRow
                        .padding(.bottom, max(safeBottom, 10))
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await viewModel.loadIfNeeded()
        }
        .sensoryFeedback(.success, trigger: viewModel.didCompleteTask)
        .sheet(isPresented: $showHomeBackgroundPicker) {
            HomeBackgroundPickerSheet()
                .environmentObject(appState)
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $sharePayload) { payload in
            ShareDrawerSheet(payload: payload, palette: appState.palette)
                .presentationDetents([.height(520), .large])
                .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $showBibleReader) {
            BibleReaderView(
                onDismiss: { showBibleReader = false },
                persistence: appState.appPersistence,
                appPalette: appState.palette
            )
        }
    }

    private var topChromeRow: some View {
        ZStack {
            HStack {
                chromeSquircleButton(
                    systemName: "chart.bar.xaxis",
                    accessibilityLabel: "Journey"
                ) {
                    $path.wrappedValue.append(MainRoute.journey)
                }
                Spacer()
                chromeSquircleButton(
                    systemName: "gearshape.fill",
                    accessibilityLabel: "Settings"
                ) {
                    $path.wrappedValue.append(MainRoute.settings)
                }
            }
            .padding(.horizontal, 20)

            Text(headerDateText)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(fg.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .shadow(color: fg.legibilityShadow, radius: 0, x: 0, y: 1)
                .shadow(color: fg.legibilityShadow.opacity(0.55), radius: 4, x: 0, y: 0)
                .padding(.horizontal, 72)
        }
    }

    private var bottomChromeRow: some View {
        HStack(alignment: .center) {
            chromeSquircleButton(
                systemName: "book.fill",
                accessibilityLabel: "Read the Bible"
            ) {
                showBibleReader = true
            }

            Spacer(minLength: 0)

            chromeSquircleButton(
                systemName: "paintpalette.fill",
                accessibilityLabel: "Home background"
            ) {
                showHomeBackgroundPicker = true
            }

            Spacer(minLength: 0)

            if viewModel.displayedRecord != nil {
                chromeSquircleButton(
                    systemName: "square.and.arrow.up",
                    accessibilityLabel: "Share"
                ) {
                    shareAction?()
                }
            } else {
                Color.clear.frame(width: 48, height: 48)
            }
        }
        .padding(.horizontal, 22)
    }

    private func chromeSquircleButton(
        systemName: String,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(fg.primary)
                .shadow(color: fg.legibilityShadow, radius: 0, x: 0, y: 1)
                .frame(width: 48, height: 48)
                .background(fg.iconBackdrop, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(fg.glassStroke, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }

    private var scrollOffsetReader: some View {
        GeometryReader { geo in
            Color.clear.preference(
                key: HomeScrollMinYPreferenceKey.self,
                value: geo.frame(in: .named("homeScroll")).minY
            )
        }
    }

    private var headerDateText: String {
        if let date = viewModel.displayedRecord?.verse.date {
            return date.formatted(.dateTime.weekday(.wide).month(.wide).day())
        }
        return Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day())
    }

    private func verseSection(record: DailyRecord) -> some View {
        VStack(spacing: 14) {
            Text("\"\(record.verse.text)\"")
                .font(.system(.title2, design: .serif))
                .multilineTextAlignment(.center)
                .foregroundStyle(fg.primary)
                .lineSpacing(6)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity)
                .shadow(color: fg.legibilityShadow, radius: 0, x: 0, y: 1)
                .shadow(color: fg.legibilityShadow.opacity(0.5), radius: 5, x: 0, y: 0)

            Text("— \(record.verse.reference)")
                .font(.headline)
                .foregroundStyle(fg.secondary)
                .shadow(color: fg.legibilityShadow, radius: 0, x: 0, y: 1)
                .shadow(color: fg.legibilityShadow.opacity(0.45), radius: 4, x: 0, y: 0)
        }
    }

    private func taskSection(record: DailyRecord) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text("TODAY'S ACTION")
                    .font(.caption2.weight(.bold))
                    .tracking(0.8)
                    .foregroundStyle(fg.secondary)
                Text(record.verse.taskTitle)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(fg.primary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(record.verse.taskDescription)
                    .font(.caption)
                    .foregroundStyle(fg.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(record.verse.taskQuote)
                .font(.caption2.italic())
                .foregroundStyle(fg.tertiary)

            if viewModel.isViewingToday {
                if record.completed {
                    taskCompletedBanner
                } else {
                    HoldToCompleteBar(
                        progress: viewModel.holdProgress,
                        secondaryText: fg.secondary,
                        trackFill: fg.taskHoldTrackFill,
                        fillColor: taskAccentGreen,
                        isCompleted: false,
                        onPress: viewModel.startHold,
                        onRelease: viewModel.cancelHold
                    )
                }
            } else {
                Text("Past day — view only")
                    .font(.caption)
                    .foregroundStyle(fg.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(fg.taskCardFill)
                .shadow(color: fg.taskCardShadow, radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(fg.glassStroke.opacity(0.85), lineWidth: 1)
        )
    }

    private var taskCompletedBanner: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(taskAccentGreenSoft)
                    .frame(width: 44, height: 44)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(taskAccentGreen)
                    .symbolRenderingMode(.hierarchical)
            }

            Text("Done for today")
                .font(.headline.weight(.semibold))
                .foregroundStyle(fg.primary)
            Text("Tomorrow brings a fresh verse and task.")
                .font(.caption)
                .foregroundStyle(fg.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }

    private var homeEmptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "book.closed")
                .font(.largeTitle)
                .foregroundStyle(fg.secondary)
                .shadow(color: fg.legibilityShadow, radius: 0, x: 0, y: 1)
            Text("Unable to load today’s verse")
                .font(.headline)
                .foregroundStyle(fg.primary)
                .shadow(color: fg.legibilityShadow, radius: 0, x: 0, y: 1)
            Text("Check your network, confirm Supabase URL and key in Info.plist, and try again.")
                .font(.subheadline)
                .foregroundStyle(fg.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(fg.glassStroke, lineWidth: 1)
        )
    }

    private var shareAction: (() -> Void)? {
        guard let record = viewModel.displayedRecord else { return nil }
        return { sharePayload = .verse(record) }
    }
}

#Preview {
    AppStatePreviewRoot { appState in
        HomeView(viewModel: appState.mainTabViewModels!.home, path: .constant(NavigationPath()))
    }
}
