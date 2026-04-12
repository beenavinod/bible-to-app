# Technology Stack — Persistent Achievements (SwiftUI + Supabase)

**Project:** Bible Life — streak milestone badges  
**Researched:** 2026-04-12  
**Scope:** Additive achievement/medal layer on existing app (no re-audit of full codebase).

**Verification note:** Context7 was not available in this workspace. Versions and API patterns were checked against [supabase-swift releases](https://github.com/supabase/supabase-swift/releases), [Supabase database/auth docs](https://supabase.com/docs/guides/database/tables), [Supabase RLS](https://supabase.com/docs/guides/auth/row-level-security), and [Apple SwiftUI `Animation`](https://developer.apple.com/documentation/swiftui/animation).

---

## Recommended stack (prescriptive)

| Layer | Choice | Version / detail | Confidence |
|-------|--------|------------------|------------|
| Remote API + auth | **Supabase Swift** (`Supabase` product) | **2.43.1** (pinned in repo `Package.resolved`; latest release **2026-04-07**) | **HIGH** — matches lockfile + GitHub release page |
| Postgres access pattern | **PostgREST** via `supabase.from(...).insert/select/upsert` | Same client | **HIGH** — official Swift examples in Supabase table docs |
| Schema & security | **Postgres tables + RLS** on `public` | Supabase Dashboard / SQL migrations | **HIGH** — Supabase requires RLS for exposed schemas |
| Server logic | **None required for v1** | Achievements are insert-on-earn + idempotent unique key | **HIGH** for this milestone scope |
| Local cache | **`UserDefaults` + `Codable`** (extend `AppPersistence`) | Keys scoped per `user_id` | **HIGH** — aligns with existing `UserDefaultsPersistence` |
| UI celebration | **SwiftUI only** — springs, `scaleEffect`, opacity, optional `symbolEffect` | iOS SDK / SwiftUI (no extra SPM for minimal badges) | **HIGH** for minimalist rings/glow per PROJECT.md |
| Async/reactivity | **Swift `async`/`await` + `ObservableObject` / `@Published`** (existing) | No new reactive framework | **HIGH** — matches current MVVM |

---

## 1. Data modeling — Supabase / Postgres

### Why this shape

- **Permanent, earned-once badges** need an **append-only** (from the client’s perspective) fact table: “user X earned milestone Y at time T.”
- **Streak breaks must not revoke rows** — store **earned facts**, not “current streak → badge mapping.”
- **Idempotency** prevents duplicate rows if the app retries after a flaky network response.

### Recommended tables

**A. `achievement_definitions` (optional but clean)**

Static catalog of the seven tiers (3, 7, 14, 30, 60, 100, 365). Keeps the client and DB aligned on `slug` / `display_order` without hard-coding only in the app.

| Column | Type | Notes |
|--------|------|--------|
| `id` | `smallserial` or `uuid` | Primary key |
| `slug` | `text` | e.g. `streak_7` — stable API contract |
| `milestone_days` | `int` | Must match product tiers |
| `display_order` | `int` | Journey grid ordering |
| `created_at` | `timestamptz` | Audit |

**RLS:** `SELECT` for `authenticated` (read-only catalog). No client `INSERT`/`UPDATE`/`DELETE` (manage via migrations / service role).

**Confidence:** **MEDIUM-HIGH** — standard normalization; optional if you prefer enums-only in Swift.

**B. `user_achievements` (required)**

One row per user per earned badge.

| Column | Type | Notes |
|--------|------|--------|
| `id` | `uuid` default `gen_random_uuid()` | Primary key |
| `user_id` | `uuid` not null | `references auth.users(id)` **or** matches your existing `profiles.id` pattern |
| `achievement_slug` | `text` not null | FK to `achievement_definitions.slug` **or** check constraint against allowed literals |
| `earned_at` | `timestamptz` not null default `now()` | Server-side “source of truth” time |
| `client_meta` | `jsonb` null | Optional: app version, locale — not required for v1 |

**Constraints**

- `unique (user_id, achievement_slug)` — makes retries safe; use **Postgres `ON CONFLICT DO NOTHING`** from a single upsert path or catch duplicate errors in Swift.

**RLS (Supabase standard pattern)**

- Enable RLS: `alter table user_achievements enable row level security;` ([Supabase RLS guide](https://supabase.com/docs/guides/auth/row-level-security)).
- **SELECT:** `using (auth.uid() = user_id)` — users read only their rows.
- **INSERT:** `with check (auth.uid() = user_id)` — users cannot forge another user’s achievements.
- **UPDATE/DELETE:** **deny** for `authenticated` (badges are permanent). No policies for update/delete, or explicit restrictive policies — prevents tampering/revocation via anon key.

**Confidence:** **HIGH** — matches Supabase’s auth.uid() policy model and PROJECT.md “permanent, never revoked.”

### What **not** to use (backend)

| Approach | Why skip for Bible Life |
|----------|-------------------------|
| **Storing only computed badge state on `user_streaks`** | Conflates *current streak* with *lifetime recognition*; breaks “permanent if streak breaks” unless you add separate columns anyway. |
| **Edge Function for every unlock** | Extra latency, ops, and cost for a simple insert with RLS; reserve for anti-cheat analytics later if needed. |
| **Realtime channels for unlock** | Unnecessary for single-user toast; local state drives UI immediately, remote is backup. |

---

## 2. Swift client — `supabase-swift`

### Pin / upgrade line

- Stay on **`Supabase` 2.x** with **`upToNextMajorVersion` from 2.0.0** as today, and **resolve to latest 2.43.x** when you run package update.
- **Verified:** Repo resolves **2.43.1**; GitHub release **2.43.1 (2026-04-07)** includes PostgREST retry improvements (503) relevant to mobile networks.

**Confidence:** **HIGH** for 2.43.1 as current; **MEDIUM** for “always latest patch” — recheck [releases](https://github.com/supabase/supabase-swift/releases) before each milestone release.

### API usage (align with existing `BibleTodoRepository`)

- **Fetch earned set:** `from("user_achievements").select().eq("user_id", value: ...)` or rely on RLS and omit filter if you use a view — simplest is explicit `user_id` matching session.
- **Record unlock:** `insert` with `[ "user_id": ..., "achievement_slug": ... ]` and handle conflict, **or** use upsert with `onConflict: "user_id,achievement_slug"` and ignore duplicate (depending on client API surface in 2.43.x).
- **DTOs:** mirror `BibleTodoSupabaseModels` style — `Decodable` structs, `Sendable` where appropriate.

**Transitive pins (informational):** `swift-crypto` 4.3.1, `swift-http-types` 1.5.1, etc., come from the resolved graph — do not add directly.

---

## 3. SwiftUI — celebration / “unlock” motion

### Standard 2025–2026 pattern (first-party, no new dependencies)

For **minimalist** badge unlock (PROJECT.md: number + ring/glow + subtle toast):

1. **State-driven reveal** — `@State` or `@Observable` flag `pendingCelebration: Achievement?`; set it immediately when local evaluation fires after successful `completeTask`.
2. **Spring emphasis** — Apple documents `Animation.smooth`, `.snappy`, `.bouncy`, and `spring(...)` for natural motion ([SwiftUI `Animation`](https://developer.apple.com/documentation/swiftui/animation)). Prefer **short** `snappy` or `smooth` + `scaleEffect` / `opacity` on the badge chip.
3. **Layered effects (still SwiftUI-only)**  
   - `Circle().stroke(lineWidth:)` + `AngularGradient` or thin `shadow` for “glow.”  
   - Optional **SF Symbol** with `symbolEffect(.bounce, value: ...)` / similar when deployment target supports it (verify against your **iOS 26.4** target in Xcode).
4. **Toast** — overlay `ZStack` + transition `.move(edge:)` + `.opacity`, or a small reusable banner component; keep duration 2–3s, no blocking modal (per requirements).

### What **not** to use (UI)

| Library / approach | Why skip |
|--------------------|----------|
| **Lottie / Rive** | Custom motion assets are **out of scope**; adds SPM weight and pipeline. |
| **UIKit `UIAlertController` for celebration** | Feels interruptive vs subtle toast; breaks SwiftUI consistency. |
| **Game Center `GKAchievement`** | Apple’s social/Game Center stack; redundant with Supabase-backed private badges and cross-device sync you already chose. |
| **Heavy particle systems** | Off-brand for “minimalist Bible Life” and harder to accessibility-tune. |

**Confidence:** **HIGH** for SwiftUI-native approach; **MEDIUM** for exact symbol effect APIs vs deployment — confirm in Xcode for your SDK.

---

## 4. Local caching strategy

### Goals (from PROJECT.md)

- **No extra network** on completion if badge already known locally.
- **Sync** on launch and after completion so reinstall / new device recovers from Supabase.

### Recommended approach

1. **Canonical local structure:** `Set<String>` of `achievement_slug` (or `Set<Int>` of `milestone_days` if you skip definitions table) stored as `Codable` in `UserDefaults`, key **`achievementsEarned.<userId>`** (mirror how other per-user keys are namespaced in repo).
2. **Write path (task completion):**  
   - Evaluate streak vs thresholds **after** successful streak update.  
   - If new: update `Set` in memory + persist `UserDefaults` **immediately** → trigger UI celebration.  
   - Enqueue / fire `Task { try await repository.insertUserAchievement(...) }` — if fails, row missing remotely but local shows earned; retry on next launch.
3. **Read path (Journey screen):**  
   - Render from **in-memory / cached `Set`** for instant grid.  
   - On `load`, merge remote: `local.formUnion(remoteSlugs)` then persist if remote had extras (device B scenario).
4. **Sign-out:** clear achievement keys for previous `user_id` together with existing cache clearing in `AppState` / repository (same discipline as `clearDailyCache`).

### What **not** to use (local store)

| Store | Why skip |
|-------|----------|
| **Core Data / SwiftData** | Small static set of strings/ints; adds migration surface inconsistent with current `UserDefaults` persistence. |
| **Keychain** | Not secret data; unnecessary complexity. |
| **Widget extension shared cache** | Widgets explicitly out of scope for badges. |

**Confidence:** **HIGH** — matches architecture doc and performance constraint.

---

## 5. Optional later (not standard for this milestone)

- **Supabase Realtime** — live multi-device badge pop (rare need for personal devotion app).
- **Postgres RPC** — `grant_achievement(user_id, slug)` with `SECURITY DEFINER` if you later move evaluation server-side for anti-cheat.

---

## Sources

- [supabase-swift Releases (2.43.1)](https://github.com/supabase/supabase-swift/releases)
- [Supabase: Tables and Data](https://supabase.com/docs/guides/database/tables)
- [Supabase: Row Level Security](https://supabase.com/docs/guides/auth/row-level-security)
- [Apple: SwiftUI Animation](https://developer.apple.com/documentation/swiftui/animation)
- Repo: `BIBLE TODO.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` (pins `supabase-swift` **2.43.1**)
