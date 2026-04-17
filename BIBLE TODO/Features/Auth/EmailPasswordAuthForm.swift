import SwiftUI

/// Shared sign-in / sign-up fields (username or email + password), matching Supabase `AppState` auth.
enum EmailPasswordAuthMode: String, CaseIterable {
    case signIn = "Sign In"
    case signUp = "Create Account"
}

struct EmailPasswordAuthForm: View {
    /// Passed explicitly so this form never depends on SwiftUI propagating `environmentObject` (missing object crashes at launch).
    let appState: AppState
    let palette: AppThemePalette
    /// Invoked after a successful `signIn` or `signUp` (e.g. advance onboarding).
    let onSuccess: (() -> Void)?

    @State private var mode: EmailPasswordAuthMode = .signIn
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isBusy = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Avoid `.segmented` Picker: it can fault on macOS when this view is removed right after sign-in.
            HStack(spacing: 4) {
                ForEach(EmailPasswordAuthMode.allCases, id: \.self) { m in
                    Button {
                        mode = m
                    } label: {
                        Text(m.rawValue)
                            .font(.subheadline.weight(mode == m ? .semibold : .regular))
                            .foregroundStyle(mode == m ? palette.primaryText : palette.secondaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(mode == m ? palette.card : Color.clear)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .background(palette.secondaryText.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text("Username or email")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(palette.secondaryText)
                TextField("e.g. james or you@email.com", text: $username)
                    .textContentType(.username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .foregroundStyle(palette.primaryText)
                    .padding(14)
                    .background(palette.card)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Password")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(palette.secondaryText)
                SecureField("Password", text: $password)
                    .textContentType(mode == .signUp ? .newPassword : .password)
                    .foregroundStyle(palette.primaryText)
                    .padding(14)
                    .background(palette.card)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            if mode == .signUp {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Confirm password")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(palette.secondaryText)
                    SecureField("Confirm", text: $confirmPassword)
                        .textContentType(.newPassword)
                        .foregroundStyle(palette.primaryText)
                        .padding(14)
                        .background(palette.card)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red.opacity(0.9))
            }

            Button {
                Task { await submit() }
            } label: {
                HStack {
                    if isBusy { ProgressView().tint(.white) }
                    Text(mode == .signIn ? "Sign In" : "Create account")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(palette.headerAccent)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .disabled(isBusy || username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || password.isEmpty)
        }
    }

    @MainActor
    private func submit() async {
        errorMessage = nil
        if mode == .signUp, password != confirmPassword {
            errorMessage = "Passwords do not match."
            return
        }
        isBusy = true
        defer { isBusy = false }
        do {
            if mode == .signUp {
                try await appState.signUp(username: username, password: password)
            } else {
                try await appState.signIn(username: username, password: password)
            }
            await Task.yield()
            onSuccess?()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
