import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var subscription: SubscriptionManager
    @StateObject private var viewModel: SettingsViewModel
    @State private var widgetSetupGuide: WidgetInfo?

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

                    #if DEBUG
                    debugPaywallCard
                    #endif
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
            .safeAreaPadding(.top, 12)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $widgetSetupGuide) { widget in
            WidgetSetupGuideView(widget: widget, palette: appState.palette) {
                widgetSetupGuide = nil
            }
        }
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
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
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
                        .buttonLabelHitRoundRect(cornerRadius: 14)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var widgetCard: some View {
        CardContainer(palette: appState.palette) {
            VStack(alignment: .leading, spacing: 14) {
                Text("Widgets")
                    .font(.headline)
                    .foregroundStyle(appState.palette.primaryText)

                ForEach(viewModel.widgets) { widget in
                    widgetRow(widget)

                    if widget.id != viewModel.widgets.last?.id {
                        Divider()
                            .overlay(appState.palette.border.opacity(0.5))
                    }
                }
            }
        }
    }

    private func widgetRow(_ widget: WidgetInfo) -> some View {
        let isLocked = widget.isPremiumOnly && !subscription.isPremium

        return HStack(spacing: 12) {
            Button {
                if isLocked {
                    subscription.presentPaywall()
                } else {
                    widgetSetupGuide = widget
                }
            } label: {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(appState.palette.accent.opacity(isLocked ? 0.15 : 0.18))
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: widget.symbolName)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(
                                isLocked
                                    ? appState.palette.secondaryText
                                    : appState.palette.accent
                            )
                    }
                    .buttonLabelHitRoundRect(cornerRadius: 10)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isLocked ? "\(widget.name), premium" : "How to add \(widget.name)")

            if isLocked {
                Button {
                    subscription.presentPaywall()
                } label: {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(widget.name)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(appState.palette.primaryText)
                            Text(widget.description)
                                .font(.caption)
                                .foregroundStyle(appState.palette.secondaryText)
                        }

                        Spacer(minLength: 0)

                        HStack(spacing: 4) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 11, weight: .semibold))
                            Text("Premium")
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(appState.palette.accentSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(appState.palette.accentSecondary.opacity(0.12))
                        )
                    }
                    .padding(.vertical, 4)
                    .buttonLabelHitRect()
                }
                .buttonStyle(.plain)
            } else {
                VStack(alignment: .leading, spacing: 3) {
                    Text(widget.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(appState.palette.primaryText)
                    Text(widget.description)
                        .font(.caption)
                        .foregroundStyle(appState.palette.secondaryText)
                }
                Spacer(minLength: 0)
            }
        }
    }

    #if DEBUG
    /// Always available in Debug builds so you can open the paywall with ⌘R → Settings (even when `isPremium` is true from StoreKit testing).
    private var debugPaywallCard: some View {
        CardContainer(palette: appState.palette) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Debug")
                    .font(.headline)
                    .foregroundStyle(appState.palette.primaryText)
                Text("Run the app with ⌘R (not SwiftUI previews), then tap below to present the premium sheet. Uses RevenueCat when API keys are set.")
                    .font(.caption)
                    .foregroundStyle(appState.palette.secondaryText)
                Button {
                    subscription.presentPaywall()
                } label: {
                    Text("Open premium paywall")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(appState.palette.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(appState.palette.border.opacity(0.85), lineWidth: 1.2)
                        )
                        .buttonLabelHitRoundRect(cornerRadius: 12)
                }
                .buttonStyle(.plain)
            }
        }
    }
    #endif

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
                            .padding(.vertical, 12)
                            .buttonLabelHitRect()
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
