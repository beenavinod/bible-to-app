# External Integrations

**Analysis Date:** 2026-04-12

## APIs & External Services

**Backend-as-a-service (Supabase):**
- Supabase project HTTP API — accessed only from the main app target via the official Swift client (`import Supabase` in `BIBLE TODO/SupabaseConfig.swift`, `BIBLE TODO/BibleTodoRepository.swift`, `BIBLE TODO/AppState.swift`).
- Auth: project URL + **anon (public) key** supplied at build time (`Config/AppConfig.xcconfig` / optional `Secrets.xcconfig` → `BIBLE TODO/Info.plist` → `SupabaseConfig.makeClient()`).
- PostgREST-style table access through the client’s `.from(...).select/update/insert` API in `BIBLE TODO/BibleTodoRepository.swift`.

**Widget extensions:**
- `StreakWidget/`, `VerseTaskWidget/`, and `LockScreenIconWidget/` timelines use **placeholder / static sample data** (e.g. `StreakEntry.placeholder` in `StreakWidget/StreakWidget.swift`). No Supabase or shared app-group `UserDefaults` usage was found in the repo; widgets are not wired to live backend data in code.

## Data Storage

**Databases:**
- **PostgreSQL (hosted by Supabase)** — implied by Supabase usage; schema consumed by the app includes tables referenced in `BIBLE TODO/BibleTodoRepository.swift`:
  - `profiles` — onboarding and user profile (`BibleTodoSupabaseModels.swift` types `ProfileRow`, `ProfileOnboardingUpdate`).
  - `verse_tasks` and nested `verses` — content and ordering for daily tasks.
  - `user_tasks` — per-user assignments and completion state.
  - `user_streaks` — streak counters and last completed date.

**File Storage:**
- Local photo library only — user-initiated save of rendered share images via `PHPhotoLibrary` in `BIBLE TODO/ShareableCardViews.swift`.

**Caching:**
- `UserDefaults.standard` — app preferences and flags in `BIBLE TODO/Services.swift` (`UserDefaultsPersistence`); daily verse payload cache keys in `BIBLE TODO/BibleTodoRepository.swift` (`getCachedDailyContent` / `cacheDailyContent`).

## Authentication & Identity

**Auth provider:**
- **Supabase Auth** — email/password flow using `client.auth.signIn`, `signUp`, `signOut`, and `session` in `BIBLE TODO/AppState.swift`.
- Username-or-email UX: `AuthEmailNormalizer` in `BIBLE TODO/SupabaseConfig.swift` maps bare usernames to synthetic emails under `users.bibletodo.app` so Supabase sees a valid email.
- UI: `BIBLE TODO/EmailPasswordAuthForm.swift`, entry via welcome/onboarding views (`BIBLE TODO/WelcomeAuthView.swift`, `BIBLE TODO/OnboardingFlowView.swift` as applicable).

## Monitoring & Observability

**Error Tracking:**
- Not detected (no Sentry, Firebase Crashlytics, or similar SDK imports in Swift sources).

**Logs:**
- Standard Swift / OS logging patterns only if used implicitly; no dedicated logging framework found in grep across Swift sources.

## CI/CD & Deployment

**Hosting:**
- Not defined in-repo (typical distribution: App Store / TestFlight via Xcode).

**CI Pipeline:**
- Not detected (no `.github/workflows` or other CI config in the repository snapshot).

## Environment Configuration

**Required env vars:**
- Not `.env`-style; use **xcconfig**: `SUPABASE_URL` and `SUPABASE_ANON_KEY` (see `Config/AppConfig.xcconfig`, `Config/Secrets.example.xcconfig`).

**Secrets location:**
- Local developer file `Secrets.xcconfig` (gitignored per `Secrets.example.xcconfig` comments); values flow into `Info.plist` build variables, not committed source.

## Webhooks & Callbacks

**Incoming:**
- None implemented in app code (no URL scheme handlers or universal-link routing found in this pass; push notification handling code not present despite `remote-notification` background mode in `BIBLE TODO/Info.plist`).

**Outgoing:**
- None — the client uses Supabase REST/RPC-style calls through the SDK; no custom webhook emitters in Swift.

---

*Integration audit: 2026-04-12*
