import SwiftUI

/// Sign-in screen for returning users, with an option to start onboarding for new account creation.
struct WelcomeAuthView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ZStack {
            AppBackgroundView(background: .plain)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Bible Life")
                        .font(.system(.largeTitle, design: .serif, weight: .regular))
                        .foregroundStyle(appState.palette.primaryText)

                    Text("Sign in with your username and password to continue your journey.")
                        .font(.subheadline)
                        .foregroundStyle(appState.palette.secondaryText)

                    EmailPasswordAuthForm(appState: appState, palette: appState.palette, onSuccess: nil, signInOnly: true)

                    createAccountSection
                }
                .padding(24)
                .padding(.vertical, 32)
            }
        }
    }

    private var createAccountSection: some View {
        VStack(spacing: 12) {
            HStack {
                Rectangle()
                    .fill(appState.palette.border.opacity(0.5))
                    .frame(height: 1)
                Text("New here?")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(appState.palette.secondaryText)
                Rectangle()
                    .fill(appState.palette.border.opacity(0.5))
                    .frame(height: 1)
            }

            Button {
                appState.redirectToOnboarding()
            } label: {
                Text("Create Account")
                    .font(.headline)
                    .foregroundStyle(appState.palette.primaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(appState.palette.card)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(appState.palette.border.opacity(0.7), lineWidth: 1.2)
                    )
                    .buttonLabelHitRoundRect(cornerRadius: 16)
            }
            .buttonStyle(.plain)
        }
    }
}
