import SwiftUI

struct ContentView: View {
    @State private var navigationPath = NavigationPath()
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Group {
            switch appState.rootPhase {
            case .configurationRequired:
                configurationRequiredView
            case .launching:
                launchSplash(showsProgress: true)
            case .needsAuth:
                WelcomeAuthView()
                    .environmentObject(appState)
            case .onboarding:
                OnboardingFlowView()
                    .environmentObject(appState)
            case .main:
                if appState.hasCompletedOnboarding, let tabs = appState.mainTabViewModels {
                    mainChrome(tabs: tabs)
                        .id(appState.authSessionRevision)
                } else if !appState.hasCompletedOnboarding {
                    OnboardingFlowView()
                        .environmentObject(appState)
                } else {
                    launchSplash(showsProgress: false)
                }
            }
        }
    }

    private func launchSplash(showsProgress: Bool) -> some View {
        let ink = Color(red: 0.34, green: 0.30, blue: 0.24)
        return ZStack {
            Color("LaunchBackground")
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image("LaunchLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))

                Text("Bible Life")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(ink)

                if showsProgress {
                    ProgressView()
                        .tint(ink)
                        .padding(.top, 4)
                }
            }
        }
    }

    private var configurationRequiredView: some View {
        VStack(spacing: 16) {
            Text("Supabase not configured")
                .font(.title2.weight(.semibold))
            Text("Add your project URL and anon key to Config/Secrets.xcconfig (copy from Secrets.example.xcconfig), then rebuild.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func mainChrome(tabs: TabViewModelsContainer) -> some View {
        ZStack {
            NavigationStack(path: $navigationPath) {
                HomeView(viewModel: tabs.home, path: $navigationPath)
                    .environmentObject(appState)
                    .navigationDestination(for: MainRoute.self) { route in
                        switch route {
                        case .journey:
                            JourneyView(viewModel: tabs.journey)
                                .environmentObject(appState)
                        case .settings:
                            SettingsView(appState: appState)
                                .environmentObject(appState)
                        }
                    }
            }

            if tabs.home.isLoadingInitialContent {
                launchSplash(showsProgress: true)
                    .transition(.opacity)
            }
        }
    }
}

#Preview {
    AppStatePreviewRoot { _ in
        ContentView()
    }
}

/// Single `AppState` instance for previews so `StateObject` / `EnvironmentObject` stay in sync.
struct AppStatePreviewRoot<Content: View>: View {
    @StateObject private var appState = AppState(swiftUIPreviewPersistence: PreviewPersistence())
    @ViewBuilder private let content: (AppState) -> Content

    init(@ViewBuilder content: @escaping (AppState) -> Content) {
        self.content = content
    }

    var body: some View {
        content(appState)
            .environmentObject(appState)
    }
}
