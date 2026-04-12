import SwiftUI

/// Sign in / sign up with username (synthetic email) or full email + password.
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

                    Text("Sign in with your username and password. If you use a username only, we create a private sign-in email for your account.")
                        .font(.subheadline)
                        .foregroundStyle(appState.palette.secondaryText)

                    EmailPasswordAuthForm(appState: appState, palette: appState.palette, onSuccess: nil)
                }
                .padding(24)
                .padding(.vertical, 32)
            }
        }
    }
}
