# Coding Conventions

**Analysis Date:** 2026-04-12

## Naming Patterns

**Files:**
- Swift sources use **PascalCase** matching the primary type or screen, e.g. `BIBLE_TODOApp.swift`, `HomeView.swift`, `BibleTodoRepository.swift`, `EmailPasswordAuthForm.swift`.
- Xcode folder names mirror feature areas: `BIBLE TODO/` (app), `BIBLE TODOTests/`, `BIBLE TODOUITests/`, widget folders `StreakWidget/`, `VerseTaskWidget/`, `LockScreenIconWidget/`.
- Config uses **PascalCase** xcconfig names: `Config/AppConfig.xcconfig`, `Config/Secrets.example.xcconfig` (actual secrets file is gitignored per project docs).

**Types:**
- **Protocols** describe roles: `BibleService`, `AppPersistence` in `BIBLE TODO/Services.swift`.
- **Concrete services** use suffixes: `SignedOutBibleService`, `MockBibleService`, `SupabaseBibleService`, `UserDefaultsPersistence`, `PreviewPersistence`.
- **Repository** pattern: `BibleTodoRepository` in `BIBLE TODO/BibleTodoRepository.swift`.
- **View models** end with `ViewModel`: `HomeViewModel`, `JourneyViewModel` in `BIBLE TODO/ViewModels.swift`.
- **Enums** for app domains: `AppTab`, `AppTheme`, `AppBackground`, `ColorToken` in `BIBLE TODO/Models.swift`; nested enums like `BibleTodoRepository.LaunchDestination` in `BIBLE TODO/BibleTodoRepository.swift`.
- **Widget scaffolding** often reuses generic names per target (e.g. `Provider`, `StreakEntry` in `StreakWidget/StreakWidget.swift`) — scoped by module.

**Functions and variables:**
- **camelCase** for methods and properties: `fetchTodayVerse()`, `resolveAppLaunchState()`, `completedRecordIDs()`.
- **Boolean** properties read as predicates: `widgetsEnabled()`, `hasCompletedOnboarding()`, `isConfigured`.
- **UserDefaults keys** live in a private nested `Key` enum with static `let` names in `UserDefaultsPersistence` (`BIBLE TODO/Services.swift`).

**JSON / API field mapping:**
- Swift properties use **camelCase**; `CodingKeys` map to **snake_case** Supabase columns, e.g. `ProfileRow` in `BIBLE TODO/BibleTodoSupabaseModels.swift`.
- Encodable payloads sent to Supabase sometimes use **snake_case property names** in Swift (`OnboardingRemotePayload`, `ProfileOnboardingUpdate`) to match JSON keys directly.

## Code Style

**Formatting:**
- No **SwiftLint** or **SwiftFormat** configuration detected in the repo root or project tree.
- Rely on **Xcode default Swift indentation** and trailing closures where used (SwiftUI `body`, async tasks).

**Linting / compiler hygiene:**
- Project uses standard **Clang** warning flags (see `BIBLE TODO.xcodeproj/project.pbxproj` build settings): e.g. treat warnings as errors for several Objective-C–related rules, strict prototypes, etc.
- Swift language version is **5.0** across targets (`SWIFT_VERSION = 5.0` in `project.pbxproj`).
- **Swift concurrency–related** build settings appear on test targets: `SWIFT_APPROACHABLE_CONCURRENCY = YES`, `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES`.

## Import Organization

**Order (observed):**
1. **Apple system frameworks** — often `Foundation` first when present, then others (`Combine`, `SwiftUI`, `WidgetKit`, `Supabase`) as needed per file.
2. No third-party import grouping file beyond **Supabase** where used (`BIBLE TODO/BibleTodoRepository.swift`, `BIBLE TODO/AppState.swift`, `BIBLE TODO/SupabaseConfig.swift`).

**Path aliases:**
- Not applicable (no SPM-style module path aliases; app module is `BIBLE_TODO`).

## Error Handling

**Domain errors:**
- Use a single **equatable** `LocalizedError` enum: `BibleTodoRepositoryError` in `BIBLE TODO/BibleTodoSupabaseModels.swift` with `errorDescription` for user-facing strings.
- **Throw** from async repository and service methods when configuration, auth, or data preconditions fail (`BibleTodoRepository`, `SignedOutBibleService`).

**Catch patterns:**
- **Repository:** `resolveAppLaunchState()` catches generic errors and returns `(.welcome, nil, nil)` instead of surfacing the error (`BIBLE TODO/BibleTodoRepository.swift`).
- **App bootstrap:** `AppState.bootstrapSupabaseLaunch()` uses `do/catch` and falls back to `.needsAuth` on failure (`BIBLE TODO/AppState.swift`).
- **View models:** `HomeViewModel.load()` sets `todayRecord = nil` on any failure; `completeTodayTask()` uses `try?` for `syncTaskCompletion` so network failures do not crash the UI (`BIBLE TODO/ViewModels.swift`).

**Prescriptive guidance for new code:**
- Prefer **typed errors** (`BibleTodoRepositoryError` or new cases) over silent `try?` when the user should see feedback or retry.
- Keep **LocalizedError** descriptions concise and actionable, matching existing cases in `BibleTodoSupabaseModels.swift`.

## Logging

**Framework:** Not detected — no `Logger`, `OSLog`, or `print` usage found in tracked Swift sources.

**Patterns:**
- When adding diagnostics, prefer **`os.Logger`** or structured logging consistent with Apple guidance; avoid `print` in shipping paths.

## Comments

**When to comment:**
- **Doc comments (`///`)** on public-ish types and important methods: e.g. `BibleService`, `SignedOutBibleService`, `MockBibleService`, `PreviewPersistence` in `BIBLE TODO/Services.swift`; `SupabaseConfig` in `BIBLE TODO/SupabaseConfig.swift`.
- **Inline comments** explain non-obvious behavior (e.g. Supabase client URL host crash note in `SupabaseConfig.makeClient()`).
- **Xcode file headers** appear in some targets (e.g. `BIBLE TODOUITests/BIBLE_TODOUITests.swift`, widget files under `StreakWidget/`).

**MARK sections:**
- Use `// MARK: - Section` to group code in large files, e.g. `BibleTodoRepository.swift`, `BibleTodoSupabaseModels.swift`.

## Function Design

**Size:**
- Large files concentrate domain logic (e.g. `BibleTodoRepository.swift`); prefer **MARK** boundaries and extracted private helpers over monolithic unbroken blocks.

**Parameters:**
- Prefer **explicit labels** for domain concepts: `userId`, `userTaskId`, `assignedDateISO`, `completed`.
- **Tuple returns** used for bootstrap results, e.g. `(LaunchDestination, UUID?, ProfileRow?)` in `resolveAppLaunchState()`.

**Return values:**
- **Optionals** for cache misses and missing rows; **throws** for hard failures (no verse, invalid configuration).

## Module Design

**Exports:**
- Types are **internal by default** at file level; no heavy use of `public` in the app target (single app module).

**Protocols + implementations:**
- **`BibleService`** abstracts data loading; production uses **`SupabaseBibleService`**, offline/unauth uses **`SignedOutBibleService`**, tests/previews use **`MockBibleService`** (`BIBLE TODO/Services.swift`, `BIBLE TODO/SupabaseBibleService.swift`).
- **`AppPersistence`** abstracts settings; **`UserDefaultsPersistence`** is production, **`PreviewPersistence`** is for SwiftUI previews (`BIBLE TODO/Services.swift`).

**SwiftUI / state:**
- Root app injects **`AppState`** via `@StateObject` and `.environmentObject` in `BIBLE TODO/BIBLE_TODOApp.swift` and `BIBLE TODO/ContentView.swift` pattern.
- **`@MainActor`** on `AppState` and view models (`BIBLE TODO/AppState.swift`, `BIBLE TODO/ViewModels.swift`) keeps UI updates on the main actor.

**Sendable / concurrency:**
- **`BibleTodoRepository`** is `Sendable`; Supabase DTOs in `BibleTodoSupabaseModels.swift` use **`Sendable`** where appropriate for cross-actor use.

---

*Convention analysis: 2026-04-12*
