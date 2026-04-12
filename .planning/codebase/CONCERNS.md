# Codebase Concerns

**Analysis Date:** 2026-04-12

## Tech Debt

**Monolithic onboarding UI:**
- Issue: `OnboardingFlowView` holds the entire multi-step flow (~31 steps), animations, and branching in one file, which complicates review, reuse, and incremental testing.
- Files: `BIBLE TODO/OnboardingFlowView.swift`
- Impact: Higher merge conflict risk, harder refactors, and weak separation between content and navigation state.
- Fix approach: Extract step-specific views and a small coordinator or state machine; keep shared chrome (progress, backdrop) in one place.

**Widgets are presentation-only:**
- Issue: `StreakWidget`, `VerseTaskWidget`, and `LockScreenIconWidget` timeline providers always return static placeholder entries, not live Supabase or cached user data.
- Files: `StreakWidget/StreakWidget.swift`, `VerseTaskWidget/VerseTaskWidget.swift`, `LockScreenIconWidget/LockScreenIconWidget.swift`
- Impact: Home Screen / Lock Screen experience does not reflect the signed-in app; product expectation may be “real” streaks and today’s task.
- Fix approach: Introduce an App Group–backed shared store (or WidgetKit intent + minimal fetch) and write from the main app when daily content or streak summary updates; align RLS and caching with widget read paths.

**Duplicated widget scaffolding:**
- Issue: Each widget extension repeats similar `TimelineProvider` patterns (placeholder-only timeline, next refresh scheduling).
- Files: Same three `*Widget.swift` files above.
- Impact: Bug fixes or policy changes must be copied three times.
- Fix approach: Shared Swift package or shared framework target consumed by all extensions (if team policy allows).

**Onboarding completion uses placeholder profile fields:**
- Issue: `completeOnboarding` sends fixed `date_of_birth` and `gender` values to Supabase regardless of user input collected in the flow.
- Files: `BIBLE TODO/AppState.swift`
- Impact: Server-side profile data is inaccurate; analytics or future features depending on those fields are misleading.
- Fix approach: Thread real values from onboarding state into `OnboardingRemotePayload` or make fields optional server-side and omit when unknown.

**Silent failure patterns (`try?`) for critical flows:**
- Issue: Remote onboarding persistence, first-task recording, sign-out, and task sync to Supabase use `try?` in several places, discarding errors without user-visible recovery.
- Files: `BIBLE TODO/AppState.swift`, `BIBLE TODO/ViewModels.swift`
- Impact: User can see success locally while server state is stale; sign-out may appear to succeed while session cleanup fails.
- Fix approach: Surface recoverable errors (toast, retry) for writes; log structured errors (e.g. `os.Logger`); keep `try?` only for explicitly optional side effects.

## Known Bugs

**Potential mis-route on transient Supabase errors:**
- Symptoms: User lands on sign-in (`needsAuth`) or default profile category even though a valid session exists, after a network or server hiccup during launch.
- Files: `BIBLE TODO/BibleTodoRepository.swift` (`resolveAppLaunchState` catch-all → `.welcome`), `BIBLE TODO/AppState.swift` (`bootstrapSupabaseLaunch` catch → `.needsAuth`), `applySignedInUser` catch → default category
- Trigger: Any thrown error while loading session/profile (not only “no session”).
- Workaround: Retry launch or sign in again; may self-correct on next cold start.

**UI test assumptions vs. real launch paths:**
- Symptoms: `testExample` fails when the app opens to `configurationRequired`, `needsAuth`, or `onboarding` instead of the main tab UI.
- Files: `BIBLE TODOUITests/BIBLE_TODOUITests.swift`, `BIBLE TODO/ContentView.swift`
- Trigger: Missing `Secrets.xcconfig`, empty Supabase keys, fresh install, or UI copy changes for strings under test.
- Workaround: Launch with injected test credentials / launch arguments, or reset state in `setUp`.

**Journey streak summary may disagree with server:**
- Symptoms: Streak card shows a streak derived partly from local `completedRecordIDs` merging logic, which can diverge from `user_streaks` returned by Supabase.
- Files: `BIBLE TODO/ViewModels.swift` (`JourneyViewModel.recalculateSummary`, `applyCompletionState`)
- Trigger: Offline completion markers, failed sync, or partial history fetches.
- Workaround: None in-app; refresh after connectivity returns.

## Security Considerations

**Supabase anon key and URL in the app bundle:**
- Risk: Keys are injected via `Info.plist` build settings (`SUPABASE_URL`, `SUPABASE_ANON_KEY`) and ship inside the client; anyone can extract them from the binary.
- Files: `BIBLE TODO/Info.plist`, `Config/AppConfig.xcconfig`, `Config/Secrets.example.xcconfig`, `BIBLE TODO/SupabaseConfig.swift`
- Current mitigation: Follows typical Supabase mobile pattern; secrets file gitignored (`Config/Secrets.xcconfig` per `.gitignore`).
- Recommendations: Rely on Row Level Security and least-privilege policies; avoid treating the anon key as a secret for sensitive logic; never embed service role keys in the app.

**Synthetic email mapping for username-only sign-in:**
- Risk: Usernames are normalized into predictable addresses under `users.bibletodo.app`, which can affect account recovery expectations and collision handling if rules change.
- Files: `BIBLE TODO/SupabaseConfig.swift` (`AuthEmailNormalizer`)
- Current mitigation: Consistent normalization on sign-in and sign-up paths via `AppState`.
- Recommendations: Document behavior in product copy; ensure Supabase auth uniqueness rules match the synthetic domain strategy.

**Daily verse cache in standard `UserDefaults`:**
- Risk: Cached daily content (verse text, task metadata) is stored unencrypted in `UserDefaults` per user id key.
- Files: `BIBLE TODO/BibleTodoRepository.swift` (`getCachedDailyContent`, `cacheDailyContent`)
- Current mitigation: Data is already visible in-app; cache is scoped by user id string in the key.
- Recommendations: If threat model requires it, use Keychain or file protection for cached payloads; clear on sign-out (already clears daily cache in `AppState.signOut`).

**HTTP allowed for Supabase URL:**
- Risk: `SupabaseConfig.makeClient()` accepts `http` as well as `https`, which could be misused in a misconfigured build.
- Files: `BIBLE TODO/SupabaseConfig.swift`
- Current mitigation: Likely dev convenience.
- Recommendations: Use `https` only in Release builds or strip `http` in production schemes.

## Performance Bottlenecks

**Large onboarding view body:**
- Problem: A single enormous SwiftUI tree increases compile time and runtime diff cost when `currentStep` changes.
- Files: `BIBLE TODO/OnboardingFlowView.swift`
- Cause: Many steps inlined in one module.
- Improvement path: Split files and use lazy construction for off-screen steps where safe.

**History fetch for home and journey:**
- Problem: `HomeViewModel` and `JourneyViewModel` each call `fetchHistory()` (default limit 60 in repository) when loading tabs, which can duplicate network work for the same session.
- Files: `BIBLE TODO/ViewModels.swift`, `BIBLE TODO/BibleTodoRepository.swift` (`fetchHistory`)
- Cause: Independent view models without a shared request cache beyond repository-level daily cache.
- Improvement path: Shared in-memory cache keyed by auth revision, or coordinator that prefetches once after sign-in.

**Streak undo path queries up to 365 rows:**
- Problem: `undoTaskCompletion` fetches up to 365 `assigned_date` rows to recompute streak client-side.
- Files: `BIBLE TODO/BibleTodoRepository.swift`
- Cause: Correctness after undo without a server-side streak recomputation endpoint.
- Improvement path: Postgres function or edge function to recompute streak atomically; or narrower date window if business rules allow.

## Fragile Areas

**`BibleTodoRepository.undoTaskCompletion` force-unwraps `lastDate`:**
- Files: `BIBLE TODO/BibleTodoRepository.swift` (uses `lastDate!` after `previousRows.first` branch where `lastDate` is non-nil by construction)
- Why fragile: Future edits to control flow could reintroduce a crash if the guard is weakened.
- Safe modification: Bind `lastDate` once with `guard let lastDate = previousRows.first?.assignedDate` in the `else` branch and use the unwrapped value throughout.
- Test coverage: No unit tests cover undo streak recomputation in `BIBLE TODOTests/BIBLE_TODOTests.swift`.

**Git-tracked Xcode user state:**
- Files: `BIBLE TODO.xcodeproj/project.xcworkspace/xcuserdata/.../UserInterfaceState.xcuserstate` (often appears modified even though `.gitignore` lists `xcuserdata/`)
- Why fragile: Noise in diffs and accidental personal UI state in shared history.
- Safe modification: Remove tracked `xcuserdata` from the index once (`git rm --cached`) so `.gitignore` takes effect for the team.
- Test coverage: Not applicable.

**String-based UI tests:**
- Files: `BIBLE TODOUITests/BIBLE_TODOUITests.swift` (matches `TODAY'S ACTION`, tab labels, settings headings)
- Why fragile: Copy or localization changes break tests without compile-time checks.
- Safe modification: Use accessibility identifiers on critical controls and query by identifier.

## Scaling Limits

**Verse pool exhaustion behavior:**
- Current capacity: `assignNextVerse` assigns the first unused verse by display order; if all are used, it falls back to `candidates.first` (reuses a verse).
- Files: `BIBLE TODO/BibleTodoRepository.swift`
- Limit: Long-term users in a fixed category see repeated tasks rather than an explicit “pool empty” UX.
- Scaling path: Add content, rotate categories, or surface `BibleTodoRepositoryError.noVerseAvailable` to the UI with messaging.

**Widget timeline refresh policy:**
- Current capacity: Placeholder timelines refresh on a coarse schedule (next 00:05 or six-hour fallback).
- Files: `StreakWidget/StreakWidget.swift`, `VerseTaskWidget/VerseTaskWidget.swift`, `LockScreenIconWidget/LockScreenIconWidget.swift`
- Limit: Even after live data exists, aggressive refresh drains battery; policy must be tuned once real data is wired.
- Scaling path: Use `WidgetCenter.shared.reloadTimelines(ofKind:)` from the app after meaningful events.

## Dependencies at Risk

**Supabase Swift SDK and auth behavior:**
- Risk: `SupabaseConfig` documents that `SupabaseClient` may crash if URL host is missing; the project guards URL parsing, but SDK upgrades could change internals.
- Files: `BIBLE TODO/SupabaseConfig.swift`
- Impact: Rare startup crash on bad configuration after dependency update.
- Migration plan: Pin Swift package versions in Xcode; re-run smoke tests on SDK bumps; keep URL validation aligned with SDK release notes.

## Missing Critical Features

**Live widget data and App Group:**
- Problem: No shared container or bridge between the main app and extensions; widgets cannot show authenticated content.
- Files: Widget targets (as above); no matches for App Group APIs in Swift sources.
- Blocks: True “today’s verse” and streak widgets matching in-app state.

**Structured logging and error surfacing:**
- Problem: Failures in view models often collapse to empty state (`todayRecord = nil`, `records = []`) without diagnostics.
- Files: `BIBLE TODO/ViewModels.swift`
- Blocks: Field debugging and support workflows.

## Test Coverage Gaps

**Repository and Supabase integration:**
- What's not tested: `BibleTodoRepository` (launch resolution, daily assignment, complete/undo streak logic, caching), `SupabaseBibleService`, `AppState` auth and onboarding flows.
- Files: `BIBLE TODO/BibleTodoRepository.swift`, `BIBLE TODO/SupabaseBibleService.swift`, `BIBLE TODO/AppState.swift`
- Risk: Regressions in streak math, RLS-shaped responses, and edge cases around profile rows go unnoticed.
- Priority: High

**View models and UI error paths:**
- What's not tested: `HomeViewModel.load` failure paths, `JourneyViewModel` summary merging, silent `syncTaskCompletion` failures.
- Files: `BIBLE TODO/ViewModels.swift`
- Risk: Blank screens in production with no automated signal.
- Priority: Medium

**Widget extensions:**
- What's not tested: No widget snapshot or timeline tests detected in repository.
- Files: `StreakWidget/`, `VerseTaskWidget/`, `LockScreenIconWidget/`
- Risk: Visual or layout regressions in extensions.
- Priority: Low until widgets show live data.

**Current unit test scope:**
- What is tested: `MockBibleService` behavior and achievement unlocking rules only.
- Files: `BIBLE TODOTests/BIBLE_TODOTests.swift`
- Risk: Very small fraction of production logic covered by Swift Testing targets.

---

*Concerns audit: 2026-04-12*
