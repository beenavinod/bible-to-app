import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var subscription: SubscriptionManager
    @StateObject private var viewModel: SettingsViewModel

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

                    if !subscription.isPremium {
                        goPremiumCard
                    }

                    widgetCard
                    accountCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
            .safeAreaPadding(.top, 12)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var goPremiumCard: some View {
        CardContainer(palette: appState.palette) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Go Premium")
                    .font(.headline)
                    .foregroundStyle(appState.palette.primaryText)
                Text("Unlock today’s task, Journey streaks, achievements, and gradient themes.")
                    .font(.subheadline)
                    .foregroundStyle(appState.palette.secondaryText)
                Button {
                    subscription.presentPaywall()
                } label: {
                    Text("See plans")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.white)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [appState.palette.headerAccent, appState.palette.accent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
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

}
