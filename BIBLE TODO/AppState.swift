import Combine
import Foundation
import SwiftUI
import Supabase

@MainActor
final class AppState: ObservableObject {
    enum RootPhase: Equatable {
        /// `SUPABASE_URL` / `SUPABASE_ANON_KEY` missing or empty (see `Config/Secrets.xcconfig`).
        case configurationRequired
        /// Resolving Supabase session.
        case launching
        /// Client OK; user must sign in.
        case needsAuth
        /// Authenticated; finish onboarding in app.
        case onboarding
        /// Main tabs (Supabase-backed after sign-in).
        case main
    }

    @Published private(set) var rootPhase: RootPhase
    @Published private(set) var service: BibleService
    @Published private(set) var authSessionRevision = 0

    @Published private(set) var theme: AppTheme
    @Published private(set) var background: AppBackground
    @Published private(set) var widgetsEnabled: Bool
    @Published private(set) var hasCompletedOnboarding: Bool
    @Published private(set) var preferredName: String?

    @Published private(set) var profileCategory: String = BibleLifeCategory.defaultSlug

    /// Shared tab view models so switching tabs does not recreate them or refetch on every visit.
    @Published private(set) var mainTabViewModels: TabViewModelsContainer?

    let supabaseClient: SupabaseClient?
    private(set) var repository: BibleTodoRepository?

    private(set) var sessionUserId: UUID?

    private let persistence: AppPersistence

    /// `true` when URL and anon key produced a `SupabaseClient`.
    var isSupabaseConfigured: Bool { supabaseClient != nil }

    /// Signed in with a valid session (data loads use `SupabaseBibleService`).
    var isSupabaseSessionActive: Bool {
        supabaseClient != nil && sessionUserId != nil
    }

    init(supabaseClient: SupabaseClient?, persistence: AppPersistence) {
        self.supabaseClient = supabaseClient
        self.persistence = persistence
        self.repository = supabaseClient.map { BibleTodoRepository(client: $0) }

        theme = persistence.selectedTheme()
        background = persistence.selectedBackground()
        widgetsEnabled = persistence.widgetsEnabled()
        hasCompletedOnboarding = persistence.hasCompletedOnboarding()
        preferredName = persistence.preferredName()

        service = SignedOutBibleService()

        if supabaseClient != nil {
            rootPhase = .launching
            Task { await bootstrapSupabaseLaunch() }
        } else {
            rootPhase = .configurationRequired
        }
    }

    /// SwiftUI previews only — unlocks main UI with mock verse data (no Supabase).
    init(swiftUIPreviewPersistence persistence: AppPersistence) {
        self.persistence = persistence
        self.supabaseClient = nil
        self.repository = nil
        self.service = MockBibleService()
        self.sessionUserId = nil
        theme = persistence.selectedTheme()
        background = persistence.selectedBackground()
        widgetsEnabled = persistence.widgetsEnabled()
        hasCompletedOnboarding = true
        preferredName = persistence.preferredName()
        rootPhase = .main
        mainTabViewModels = TabViewModelsContainer(service: service, persistence: persistence)
    }

    var palette: AppThemePalette {
        theme.palette
    }

    // MARK: - Bootstrap

    private func bootstrapSupabaseLaunch() async {
        guard let repository else {
            rootPhase = .configurationRequired
            return
        }
        do {
            let (dest, userId, profile) = try await repository.resolveAppLaunchState()
            switch dest {
            case .welcome:
                rootPhase = .needsAuth
            case .onboarding:
                guard let userId else {
                    rootPhase = .needsAuth
                    return
                }
                await applySignedInUser(userId: userId, existingProfile: profile)
                rootPhase = .onboarding
            case .home:
                guard let userId else {
                    rootPhase = .needsAuth
                    return
                }
                await applySignedInUser(userId: userId, existingProfile: profile)
                rebuildMainTabViewModels()
                rootPhase = .main
            }
        } catch {
            rootPhase = .needsAuth
        }
    }

    private func applySignedInUser(userId: UUID, existingProfile: ProfileRow? = nil) async {
        sessionUserId = userId
        guard let repository else { return }
        do {
            let profile: ProfileRow
            if let existingProfile {
                profile = existingProfile
            } else {
                profile = try await repository.fetchProfile(userId: userId)
            }
            profileCategory = BibleLifeCategory.resolvedSlug(stored: profile.onboardingData.category)
            hasCompletedOnboarding = profile.onboardingCompleted
            preferredName = profile.onboardingData.displayName ?? preferredName
            if profile.onboardingCompleted {
                persistence.setHasCompletedOnboarding(true)
                persistence.setPreferredName(profile.onboardingData.displayName)
            }
        } catch {
            profileCategory = BibleLifeCategory.defaultSlug
        }
        useSupabaseService()
    }

    private func rebuildMainTabViewModels() {
        mainTabViewModels = TabViewModelsContainer(service: service, persistence: persistence)
    }

    private func useSupabaseService() {
        guard let userId = sessionUserId, let repository else {
            service = SignedOutBibleService()
            authSessionRevision += 1
            return
        }
        service = SupabaseBibleService(
            userId: userId,
            category: BibleLifeCategory.resolvedSlug(stored: profileCategory),
            repository: repository
        )
        authSessionRevision += 1
    }

    // MARK: - Auth

    func signIn(username: String, password: String) async throws {
        guard let client = supabaseClient else { throw BibleTodoRepositoryError.invalidConfiguration }
        let email = AuthEmailNormalizer.authEmail(from: username)
        try await client.auth.signIn(email: email, password: password)
        try await finalizeSessionAfterAuth()
    }

    func signUp(username: String, password: String) async throws {
        guard let client = supabaseClient else { throw BibleTodoRepositoryError.invalidConfiguration }
        let email = AuthEmailNormalizer.authEmail(from: username)
        _ = try await client.auth.signUp(email: email, password: password)
        try await finalizeSessionAfterAuth()
    }

    private func finalizeSessionAfterAuth() async throws {
        guard let client = supabaseClient, let repository else {
            throw BibleTodoRepositoryError.invalidConfiguration
        }
        let session = try await client.auth.session
        let userId = session.user.id
        let profile = try await repository.fetchProfile(userId: userId)
        await applySignedInUser(userId: userId, existingProfile: profile)
        if profile.onboardingCompleted {
            hasCompletedOnboarding = true
            persistence.setHasCompletedOnboarding(true)
            rebuildMainTabViewModels()
            rootPhase = .main
        } else {
            hasCompletedOnboarding = false
            persistence.setHasCompletedOnboarding(false)
            rootPhase = .onboarding
        }
    }

    func signOut() async {
        if let client = supabaseClient {
            try? await client.auth.signOut()
        }
        if let uid = sessionUserId {
            repository?.clearDailyCache(userId: uid)
        }
        sessionUserId = nil
        mainTabViewModels = nil
        service = SignedOutBibleService()
        authSessionRevision += 1
        hasCompletedOnboarding = persistence.hasCompletedOnboarding()
        rootPhase = supabaseClient != nil ? .needsAuth : .configurationRequired
    }

    // MARK: - Settings / theme

    func setTheme(_ theme: AppTheme) {
        self.theme = theme
        persistence.setSelectedTheme(theme)
    }

    func setBackground(_ background: AppBackground) {
        self.background = background
        persistence.setSelectedBackground(background)
    }

    func setWidgetsEnabled(_ isEnabled: Bool) {
        widgetsEnabled = isEnabled
        persistence.setWidgetsEnabled(isEnabled)
    }

    /// Persists onboarding, records the canonical first task as completed for today, then enters main.
    func completeOnboarding(name: String) async {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        preferredName = trimmedName.isEmpty ? nil : trimmedName
        hasCompletedOnboarding = true
        persistence.setPreferredName(preferredName)
        persistence.setHasCompletedOnboarding(true)

        if let userId = sessionUserId, let repository {
            let display = preferredName ?? "Friend"
            let payload = OnboardingRemotePayload(
                display_name: display,
                date_of_birth: "2000-01-01",
                gender: "prefer-not-to-say",
                category: BibleLifeCategory.resolvedSlug(stored: profileCategory)
            )
            try? await repository.completeOnboarding(userId: userId, payload: payload)
            try? await repository.recordCanonicalFirstOnboardingTaskCompleted(userId: userId)
            repository.clearDailyCache(userId: userId)
        }

        rebuildMainTabViewModels()
        if rootPhase == .onboarding {
            rootPhase = .main
        }
    }
}
