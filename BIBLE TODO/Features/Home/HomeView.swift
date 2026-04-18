import SwiftUI

private struct HomeScrollMinYPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private let taskAccentGreen = Color(red: 0.16, green: 0.58, blue: 0.36)
private let taskAccentGreenSoft = Color(red: 0.16, green: 0.58, blue: 0.36).opacity(0.18)

/// Matches `topChromeRow` + inset padding for scroll `minHeight` math (see `safeAreaInset` below).
private let homeTopChromeLayoutHeight: CGFloat = 56

struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var subscription: SubscriptionManager
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
                let safeBottom = geo.safeAreaInsets.bottom
                let chromeButtonSide: CGFloat = 48
                /// Tighter than full home-indicator inset so the row sits closer to the screen edge (still above a small floor).
                let bottomChromeOuter: CGFloat = max(safeBottom - 10, 6)
                let bottomChromeTop = bottomChromeOuter + chromeButtonSide
                /// `GeometryReader` is already laid out inside the screen safe rectangle; `.safeAreaInset` adds the header without stacking `safeAreaInsets.top` again (which caused the large gap under the Dynamic Island).
                let middleBandMinHeight = max(
                    120,
                    geo.size.height - homeTopChromeLayoutHeight - bottomChromeTop
                )

                ScrollView {
                    VStack(spacing: 0) {
                        Color.clear
                            .frame(height: 0)
                            .background(scrollOffsetReader)

                        VStack(spacing: 0) {
                            Spacer(minLength: 0)

                            if viewModel.isLoadingInitialContent {
                                Color.clear
                                    .frame(minHeight: middleBandMinHeight)
                            } else if let record = viewModel.displayedRecord {
                                VStack(spacing: 0) {
                                    HomeDayVerseSection(record: record, fg: fg)
                                    homeTaskCard(record: record)
                                        .padding(.top, 28)
                                }
                            } else {
                                homeEmptyState
                            }

                            Spacer(minLength: 0)
                        }
                        .frame(minHeight: middleBandMinHeight)
                        .padding(.horizontal, 20)

                        Color.clear.frame(height: bottomChromeTop)
                    }
                }
                .scrollIndicators(.hidden)
                .coordinateSpace(name: "homeScroll")
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .safeAreaInset(edge: .top, spacing: 0) {
                    topChromeRow
                        .padding(.top, 4)
                        .padding(.bottom, 4)
                }
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
                .overlay(alignment: .bottom) {
                    bottomChromeRow
                        .padding(.bottom, bottomChromeOuter)
                }
                .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        /// Removes the invisible navigation chrome that still consumes vertical space when only using `.toolbar(.hidden)`.
        .toolbarBackground(.hidden, for: .navigationBar)
        .task {
            await viewModel.loadIfNeeded()
        }
        .sensoryFeedback(.success, trigger: viewModel.didCompleteTask)
        .sheet(isPresented: $showHomeBackgroundPicker) {
            HomeBackgroundPickerSheet()
                .environmentObject(appState)
                .environmentObject(subscription)
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $sharePayload) { payload in
            ShareDrawerSheet(
                payload: payload,
                palette: appState.palette,
                verseShareIncludesTask: subscription.isPremium
            )
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
        .padding(.horizontal, 20)
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

    private func homeTaskCard(record: DailyRecord) -> some View {
        HomeDayTaskCard(record: record, fg: fg, isViewingToday: viewModel.isViewingToday) {
            Group {
                if viewModel.isViewingToday {
                    HomePressHoldCircleView(
                        progress: viewModel.holdProgress,
                        isCompleted: record.completed,
                        isInteractive: !record.completed,
                        primaryText: fg.primary,
                        secondaryText: fg.secondary,
                        accent: taskAccentGreen,
                        accentSoft: taskAccentGreenSoft,
                        onPress: viewModel.startHold,
                        onRelease: viewModel.cancelHold
                    )
                } else if record.completed {
                    HomePressHoldCircleView(
                        progress: 1,
                        isCompleted: true,
                        isInteractive: false,
                        primaryText: fg.primary,
                        secondaryText: fg.secondary,
                        accent: taskAccentGreen,
                        accentSoft: taskAccentGreenSoft,
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
                                .foregroundStyle(fg.secondary)
                        }
                        Text("View only")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(fg.secondary)
                    }
                }
            }
            .padding(.top, 2)
        }
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
        return {
            sharePayload = .verse(record, wallpaper: appState.homeWallpaper)
            appState.awardFirstShareBadgeIfNeeded()
        }
    }
}

#Preview {
    AppStatePreviewRoot { appState, _ in
        HomeView(viewModel: appState.mainTabViewModels!.home, path: .constant(NavigationPath()))
    }
}
