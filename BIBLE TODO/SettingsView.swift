import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel: SettingsViewModel

    init(appState: AppState) {
        _viewModel = StateObject(wrappedValue: SettingsViewModel(appState: appState))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView(background: appState.background)

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        TopBar(title: "Settings", subtitle: "Customize Bible Life", palette: appState.palette)

                        widgetCard
                        themeCard
                        backgroundCard
                        placeholderCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 110)
                }
                .safeAreaPadding(.top, 12)
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
