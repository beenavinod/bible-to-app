# Architecture

**Analysis Date:** 2026-04-12

## Pattern Overview

**Overall:** Single-window SwiftUI application with a composition-root `AppState`, protocol-based data access (`BibleService`, `AppPersistence`), and a dedicated Supabase repository layer. Three WidgetKit extension targets ship alongside the main app; widget timelines currently use **static/placeholder** entries and do not read shared app state or App Groups.

**Key Characteristics:**
- Root navigation is driven by `AppState.RootPhase` (configuration, auth, onboarding, main tabs).
- View models (`HomeViewModel`, `JourneyViewModel`) depend on `BibleService` and `AppPersistence`, not on `SupabaseClient` directly.
- Remote persistence uses Supabase PostgREST via `supabase-swift` (`BIBLE TODO.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` pins `supabase-swift` 2.43.1).
- Local persistence mixes `UserDefaults` for settings/completion IDs (`UserDefaultsPersistence` in `BIBLE TODO/Services.swift`) and `UserDefaults.standard` inside `BIBLE TODO/BibleTodoRepository.swift` for per-user daily content cache keys.

## Layers

**App shell / composition root:**
- Purpose: Bootstrap Supabase client, choose `BibleService` implementation, own session lifecycle and global UI preferences.
- Location: `BIBLE TODO/BIBLE_TODOApp.swift`, `BIBLE TODO/AppState.swift`
- Contains: `@main` app entry, `AppState` (`ObservableObject`), phase machine, auth methods, theme/background/widget toggles.
- Depends on: `SupabaseConfig`, `BibleTodoRepository`, `BibleService` implementations, `AppPersistence`.
- Used by: All views via `@EnvironmentObject var appState: AppState`.

**Presentation (SwiftUI views):**
- Purpose: Render UI and bind to view models or `AppState`.
- Location: `BIBLE TODO/*.swift` views (e.g. `BIBLE TODO/ContentView.swift`, `BIBLE TODO/HomeView.swift`, `BIBLE TODO/JourneyView.swift`, `BIBLE TODO/SettingsView.swift`, `BIBLE TODO/WelcomeAuthView.swift`, `BIBLE TODO/OnboardingFlowView.swift`), shared UI in `BIBLE TODO/Components.swift`, `BIBLE TODO/CalendarComponents.swift`, `BIBLE TODO/ShareableCardViews.swift`.
- Contains: Feature screens, custom tab chrome in `ContentView`, navigation stacks.
- Depends on: `AppState`, `HomeViewModel`, `JourneyViewModel`, models from `BIBLE TODO/Models.swift`.
- Used by: `BIBLE_TODOApp` → `ContentView`.

**Feature view models:**
- Purpose: Screen-level async loading, UI-specific state (hold-to-complete, calendar expansion), and bridging to `AppState` for settings/sign-out.
- Location: `BIBLE TODO/ViewModels.swift`, container `BIBLE TODO/TabViewModelsContainer.swift`
- Contains: `HomeViewModel`, `JourneyViewModel`, `SettingsViewModel`; `TabViewModelsContainer` keeps home/journey models alive across tab switches.
- Depends on: `BibleService`, `AppPersistence`, `AppState` (settings VM only).
- Used by: Corresponding views; `AppState` creates `TabViewModelsContainer` when entering `.main`.

**Domain-facing protocols & app services:**
- Purpose: Stable API for “today’s verse,” history, streak summary, and task sync without exposing Supabase types to views.
- Location: `BIBLE TODO/Services.swift`
- Contains: `BibleService`; `SignedOutBibleService` (throws `BibleTodoRepositoryError.notAuthenticated`); `MockBibleService` (previews/tests); `AppPersistence`; `UserDefaultsPersistence`; `PreviewPersistence`.
- Depends on: Types in `BIBLE TODO/Models.swift`, errors in `BIBLE TODO/BibleTodoSupabaseModels.swift`.
- Used by: `AppState`, view models, unit tests (`BIBLE TODOTests/BIBLE_TODOTests.swift`).

**Remote data & mapping:**
- Purpose: Encapsulate PostgREST queries, streak updates, onboarding profile writes, and map rows to `DailyContentCache` / domain records.
- Location: `BIBLE TODO/BibleTodoRepository.swift`, `BIBLE TODO/SupabaseBibleService.swift`, DTOs/errors `BIBLE TODO/BibleTodoSupabaseModels.swift`, date helpers `BIBLE TODO/BibleTodoDate.swift`, onboarding constants `BIBLE TODO/FirstOnboardingTask.swift`, category slugs `BIBLE TODO/BibleLifeCategory.swift`.
- Contains: `BibleTodoRepository` (`Sendable`, owns `SupabaseClient`); `SupabaseBibleService` implements `BibleService` using `userId` + `category` + repository.
- Depends on: `Supabase` package, JSON types for profiles, `user_tasks`, `verse_tasks`, `verses`, `user_streaks`.
- Used by: `AppState` after sign-in (`useSupabaseService()`).

**Configuration:**
- Purpose: Inject `SUPABASE_URL` and `SUPABASE_ANON_KEY` into the app bundle and validate client construction.
- Location: `Config/AppConfig.xcconfig`, `Config/Secrets.example.xcconfig` (local `Secrets.xcconfig` is gitignored per example comments), `BIBLE TODO/Info.plist` (`$(SUPABASE_URL)` / `$(SUPABASE_ANON_KEY)`), `BIBLE TODO/SupabaseConfig.swift`
- Contains: xcconfig layering; `SupabaseConfig.makeClient()` reads `Bundle.main` Info.plist keys; `AuthEmailNormalizer` for username→email mapping.

**Widget extensions (separate targets):**
- Purpose: Home Screen / Lock Screen widgets and (in `StreakWidget`) Control + Live Activity bundle entry.
- Location: `StreakWidget/`, `VerseTaskWidget/`, `LockScreenIconWidget/`
- Contains: `@main` widget bundles (`*Bundle.swift`), `TimelineProvider` types, SwiftUI entry views, `Assets.xcassets`, per-target `Info.plist`. `StreakWidget/StreakWidgetLiveActivity.swift` is an ActivityKit template. `AppIntent.swift` files provide WidgetKit/AppIntents scaffolding (e.g. `LockScreenIconWidget/AppIntent.swift`).
- Depends on: WidgetKit, SwiftUI; **no** import of the main app module or Supabase in the current Swift sources.
- Used by: iOS system at runtime as app extensions.

**Tests:**
- Purpose: Swift Testing against `@testable import BIBLE_TODO` for mock service and achievement logic.
- Location: `BIBLE TODOTests/BIBLE_TODOTests.swift`, UI test harness `BIBLE TODOUITests/`.

## Data Flow

**Cold start (Supabase configured):**
1. `BIBLE_TODOApp` constructs `AppState` with `SupabaseConfig.makeClient()` and `UserDefaultsPersistence()` (`BIBLE TODO/BIBLE_TODOApp.swift`).
2. `AppState` sets `rootPhase` to `.launching` and runs `bootstrapSupabaseLaunch()` (`BIBLE TODO/AppState.swift`).
3. `BibleTodoRepository.resolveAppLaunchState()` reads `client.auth.session` and `profiles` row (`BIBLE TODO/BibleTodoRepository.swift`).
4. On success: `applySignedInUser` loads profile fields, then `useSupabaseService()` swaps `service` to `SupabaseBibleService`. On failure: `.needsAuth`.

**Sign-in / sign-up:**
1. `AppState.signIn` / `signUp` call `SupabaseClient.auth`, then `finalizeSessionAfterAuth()` which fetches profile and sets `rootPhase` to `.onboarding` or `.main` (`BIBLE TODO/AppState.swift`).

**Today’s verse and completion (main app):**
1. `HomeView` triggers `HomeViewModel.loadIfNeeded()` via `.task` (`BIBLE TODO/HomeView.swift`).
2. `HomeViewModel` concurrently calls `service.fetchTodayVerse()` and `service.fetchHistory()` (`BIBLE TODO/ViewModels.swift`).
3. `SupabaseBibleService` delegates to `repository.loadDailyContent`, which uses in-memory cache in `UserDefaults`, existing `user_tasks` row, or `assignNextVerse` (`BIBLE TODO/SupabaseBibleService.swift`, `BIBLE TODO/BibleTodoRepository.swift`).
4. Hold-to-complete updates local `UserDefaultsPersistence.completedRecordIDs` and fires `service.syncTaskCompletion`, which maps to `completeTask` / `undoTaskCompletion` on the repository (`BIBLE TODO/ViewModels.swift`, `BIBLE TODO/SupabaseBibleService.swift`).

**Journey / streaks:**
1. `JourneyViewModel.load` fetches history and `fetchStreakSummary` from `BibleService`, merges local completion IDs, and recomputes a local streak prefix for display (`BIBLE TODO/ViewModels.swift`).

**Widgets:**
1. Each extension’s `Provider.getTimeline` returns placeholder or canned `TimelineEntry` values (e.g. `StreakWidget/StreakWidget.swift`, `VerseTaskWidget/VerseTaskWidget.swift`, `LockScreenIconWidget/LockScreenIconWidget.swift`). No shared container or repository calls in current code.

**State Management:**
- Global: `AppState` as `StateObject` + `environmentObject`.
- Tab-scoped: `TabViewModelsContainer` holds `HomeViewModel` and `JourneyViewModel` across tab changes (`BIBLE TODO/TabViewModelsContainer.swift`).
- Local UI: `@State` in views (e.g. `ContentView` selected tab).
- Previews: `AppStatePreviewRoot` + `PreviewPersistence` + `AppState(swiftUIPreviewPersistence:)` (`BIBLE TODO/ContentView.swift`, `BIBLE TODO/AppState.swift`).

## Key Abstractions

**`BibleService`:**
- Purpose: Feature-level API for verse/history/streaks and task sync.
- Examples: `BIBLE TODO/Services.swift` (protocol), `BIBLE TODO/SupabaseBibleService.swift`, `SignedOutBibleService`, `MockBibleService`.
- Pattern: Strategy selection in `AppState` based on auth.

**`AppPersistence`:**
- Purpose: Persist theme, background, widget flag, onboarding flags, preferred name, and local completion ID set.
- Examples: `UserDefaultsPersistence`, `PreviewPersistence` in `BIBLE TODO/Services.swift`.
- Pattern: Protocol for testability and previews.

**`BibleTodoRepository`:**
- Purpose: Single place for Supabase table access and daily-cache serialization.
- Examples: `BIBLE TODO/BibleTodoRepository.swift`.
- Pattern: Thin data layer; maps PostgREST shapes to `DailyContentCache` and streak helpers.

**`DailyContentCache` → `DailyRecord`:**
- Purpose: Bridge cached/remote rows to UI models.
- Examples: `BIBLE TODO/BibleTodoSupabaseModels.swift` (struct), `extension DailyContentCache` in `BIBLE TODO/SupabaseBibleService.swift` (`toDailyRecord`).

## Entry Points

**Main application:**
- Location: `BIBLE TODO/BIBLE_TODOApp.swift`
- Triggers: iOS launches the `BIBLE TODO` target.
- Responsibilities: Instantiate `AppState`, present `WindowGroup` with `ContentView` and `environmentObject`.

**Widget extension bundles:**
- `StreakWidget/StreakWidgetBundle.swift` — `@main` exposes `StreakWidget`, `StreakWidgetControl`, `StreakWidgetLiveActivity`.
- `VerseTaskWidget/VerseTaskWidgetBundle.swift` — registers verse/task widget.
- `LockScreenIconWidget/LockScreenIconWidgetBundle.swift` — registers lock screen accessory widget.

**Xcode project / build:**
- Location: `BIBLE TODO.xcodeproj/project.pbxproj`
- Native targets: `BIBLE TODO`, `BIBLE TODOTests`, `BIBLE TODOUITests`, `StreakWidgetExtension`, `VerseTaskWidgetExtension`, `LockScreenIconWidgetExtension`.

## Error Handling

**Strategy:** Swift `async`/`throws` at repository and service boundaries; UI view models catch and degrade to empty/nil state (e.g. `HomeViewModel.load` sets `todayRecord = nil` on error).

**Patterns:**
- Typed errors: `BibleTodoRepositoryError` (`BIBLE TODO/BibleTodoSupabaseModels.swift`) conforms to `LocalizedError`.
- Auth/configuration: `SignedOutBibleService` surfaces `notAuthenticated`; missing Supabase config yields `rootPhase == .configurationRequired` and a dedicated view in `BIBLE TODO/ContentView.swift`.
- Launch bootstrap: `bootstrapSupabaseLaunch` falls back to `.needsAuth` on throw (`BIBLE TODO/AppState.swift`).

## Cross-Cutting Concerns

**Logging:** No centralized logging framework detected; failures are mostly silent at the UI layer (empty states) or use `try?` for non-blocking side effects (e.g. onboarding completion in `AppState.completeOnboarding`).

**Validation:** Username/email normalization via `AuthEmailNormalizer` before Supabase auth (`BIBLE TODO/SupabaseConfig.swift`).

**Authentication:** Supabase Auth session held by `SupabaseClient`; `AppState` tracks `sessionUserId` and coordinates sign-out cache clearing (`repository?.clearDailyCache`).

---

*Architecture analysis: 2026-04-12*
