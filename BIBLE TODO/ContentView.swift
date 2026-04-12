import SwiftUI

struct ContentView: View {
    @State private var selectedTab: AppTab = .home
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Group {
            switch appState.rootPhase {
            case .configurationRequired:
                configurationRequiredView
            case .launching:
                ProgressView("Loading…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .needsAuth:
                WelcomeAuthView()
                    .environmentObject(appState)
            case .onboarding:
                OnboardingFlowView()
                    .environmentObject(appState)
            case .main:
                if appState.hasCompletedOnboarding {
                    mainChrome
                        .id(appState.authSessionRevision)
                } else {
                    OnboardingFlowView()
                        .environmentObject(appState)
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

    private var mainChrome: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .home:
                    HomeView(appState: appState)
                        .environmentObject(appState)
                case .journey:
                    JourneyView(appState: appState)
                        .environmentObject(appState)
                case .settings:
                    SettingsView(appState: appState)
                        .environmentObject(appState)
                }
            }

            customTabBar
                .padding(.horizontal, 20)
                .padding(.bottom, 18)
        }
    }

    private var customTabBar: some View {
        HStack(spacing: 18) {
            tabButton(tab: .home, title: "Today", icon: "house")
            tabButton(tab: .journey, title: "Journey", icon: "chart.bar.xaxis")
            tabButton(tab: .settings, title: "Settings", icon: "gearshape")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(appState.palette.card)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(appState.palette.border.opacity(0.65), lineWidth: 1)
        )
        .shadow(color: appState.palette.shadow, radius: 14, x: 0, y: 8)
    }

    private func tabButton(tab: AppTab, title: String, icon: String) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(isSelected ? appState.palette.headerAccent.opacity(0.75) : appState.palette.tabInactive.opacity(0.45))
                        .frame(width: 58, height: 44)

                    Image(systemName: icon)
                        .font(.headline)
                        .foregroundStyle(isSelected ? .white : appState.palette.primaryText)
                }

                Text(title)
                    .font(.caption)
                    .foregroundStyle(appState.palette.secondaryText)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
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
