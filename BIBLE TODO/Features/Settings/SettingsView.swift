import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel: SettingsViewModel
    @State private var showHomeBackgroundPicker = false

    init(appState: AppState) {
        _viewModel = StateObject(wrappedValue: SettingsViewModel(appState: appState))
    }

    var body: some View {
        ZStack {
            AppBackgroundView(background: appState.background)

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text("Customize Bible Life")
                        .font(.subheadline)
                        .foregroundStyle(appState.palette.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    widgetCard
                    themeCard
                    homeBackgroundRow
                    backgroundCard
                    accountCard
                    placeholderCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
            .safeAreaPadding(.top, 12)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showHomeBackgroundPicker) {
            HomeBackgroundPickerSheet()
                .environmentObject(appState)
                .presentationDragIndicator(.visible)
        }
    }

    private var homeBackgroundRow: some View {
        CardContainer(palette: appState.palette) {
            VStack(alignment: .leading, spacing: 14) {
                Text("Home")
                    .font(.headline)
                    .foregroundStyle(appState.palette.primaryText)

                Button {
                    showHomeBackgroundPicker = true
                } label: {
                    HStack {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.title3)
                            .foregroundStyle(appState.palette.accent)
                            .frame(width: 44, height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(appState.palette.canvas.opacity(0.9))
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Home background")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(appState.palette.primaryText)
                            Text("Wallpaper for the Today tab only.")
                                .font(.subheadline)
                                .foregroundStyle(appState.palette.secondaryText)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(appState.palette.secondaryText.opacity(0.8))
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var widgetCard: some View {
        CardContainer(palette: appState.palette) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Widget")
                    .font(.headline)
                    .foregroundStyle(appState.palette.primaryText)

                Toggle(isOn: Binding(
                    get: { viewModel.widgetsEnabled },
                    set: { viewModel.setWidgetsEnabled($0) }
                )) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Enable Home Screen widget")
                            .foregroundStyle(appState.palette.primaryText)
                        Text("Keep the daily verse visible outside the app.")
                            .font(.subheadline)
                            .foregroundStyle(appState.palette.secondaryText)
                    }
                }
                .tint(appState.palette.accent)

                WidgetPreviewCard(
                    palette: appState.palette,
                    verseReference: "Psalm 23:1-3",
                    taskTitle: "Give Thanks"
                )

                Text("This is an in-app sample widget preview. A real Home Screen widget requires a WidgetKit extension target.")
                    .font(.footnote)
                    .foregroundStyle(appState.palette.secondaryText)
            }
        }
    }

    private var themeCard: some View {
        CardContainer(palette: appState.palette) {
            VStack(alignment: .leading, spacing: 14) {
                Text("Themes")
                    .font(.headline)
                    .foregroundStyle(appState.palette.primaryText)

                ForEach(viewModel.themes, id: \.self) { theme in
                    Button {
                        viewModel.setTheme(theme)
                    } label: {
                        HStack {
                            ThemeSwatchView(
                                colors: [theme.palette.headerAccent, theme.palette.accentSecondary],
                                isSelected: theme == viewModel.selectedTheme,
                                palette: appState.palette
                            )
                            Text(theme.displayName)
                                .foregroundStyle(appState.palette.primaryText)
                            Spacer()
                            if theme == viewModel.selectedTheme {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(appState.palette.accent)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var backgroundCard: some View {
        CardContainer(palette: appState.palette) {
            VStack(alignment: .leading, spacing: 14) {
                Text("Backgrounds")
                    .font(.headline)
                    .foregroundStyle(appState.palette.primaryText)

                ForEach(viewModel.backgrounds, id: \.self) { background in
                    Button {
                        viewModel.setBackground(background)
                    } label: {
                        HStack {
                            ThemeSwatchView(
                                colors: background.gradientColors,
                                isSelected: background == viewModel.selectedBackground,
                                palette: appState.palette
                            )
                            Text(background.displayName)
                                .foregroundStyle(appState.palette.primaryText)
                            Spacer()
                            if background == viewModel.selectedBackground {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(appState.palette.accent)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var accountCard: some View {
        CardContainer(palette: appState.palette) {
            VStack(alignment: .leading, spacing: 14) {
                Text("Account")
                    .font(.headline)
                    .foregroundStyle(appState.palette.primaryText)

                if appState.isSupabaseSessionActive {
                    Button {
                        Task { await viewModel.signOut() }
                    } label: {
                        Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
                            .foregroundStyle(appState.palette.primaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                } else if appState.isSupabaseConfigured {
                    Text("Sign in from the welcome screen to sync your progress.")
                        .font(.subheadline)
                        .foregroundStyle(appState.palette.secondaryText)
                } else {
                    Text("Configure Config/Secrets.xcconfig with your Supabase URL and anon key, then rebuild.")
                        .font(.subheadline)
                        .foregroundStyle(appState.palette.secondaryText)
                }
            }
        }
    }

    private var placeholderCard: some View {
        CardContainer(palette: appState.palette) {
            VStack(alignment: .leading, spacing: 14) {
                Text("Future Features")
                    .font(.headline)
                    .foregroundStyle(appState.palette.primaryText)

                Label("Notifications", systemImage: "bell.badge")
                Label("Account", systemImage: "person.crop.circle")
                Label("Sync & Backup", systemImage: "icloud")
            }
            .foregroundStyle(appState.palette.secondaryText)
        }
    }
}
