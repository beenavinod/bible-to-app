# Project Research Summary

**Project:** Bible Life — streak milestone badges (persistent achievements)  
**Domain:** Habit / devotional app gamification layer on existing SwiftUI + Supabase iOS app  
**Researched:** 2026-04-12  
**Confidence:** HIGH (stack, architecture, pitfalls anchored to repo + official docs); MEDIUM (feature landscape — category synthesis, not formal teardown)

## Executive Summary

Bible Life is adding an **additive achievement layer**: seven streak milestones (3 / 7 / 14 / 30 / 60 / 100 / 365 days), **permanent once earned**, minimalist Journey UI, subtle celebrations, and **dual persistence** (UserDefaults + Supabase) without changing how streaks are calculated. Research across stack, features, architecture, and pitfalls converges on a **thin, event-driven design**: after a successful `completeTask`, use **server-authoritative streak output** (`StreakInfo`) as the only input to a **pure evaluator**, persist earned facts in a dedicated `user_achievements` table with **RLS and unique (user_id, achievement_slug)**, and keep local cache for instant UI and offline-friendly reads.

Category apps (YouVersion-style badges, Hallow streak framing, habit trackers) establish **table stakes**: visible streak rules, milestone tiers with early wins, a collection view, locked/unlocked affordances, progress toward the next tier, non-blocking earn feedback, and honest behavior when the current streak breaks while lifetime medals remain. Bible Life’s **differentiators**—permanent medals, minimalist ring/glow visuals, single streak channel, Journey placement—are coherent if **copy and data** clearly separate *current streak* from *earned medals*.

**Primary risks** are integration and integrity, not novelty: evaluating from the wrong streak source (Journey merge vs `user_streaks`), TOCTOU/double-grant without DB idempotency, stale cache or swallowed errors causing false unlocks, Journey regressions if badge fetch is not fault-isolated, and over-engineering a rules engine for seven static thresholds. Mitigations: **thread `StreakInfo` through `SupabaseBibleService`**, **unique constraint + conflict-safe insert**, **explicit toast/earned policy** aligned with permanent badges, **lazy/parallel badge loading with isolated errors**, and a **small enum + pure function** tested in isolation. Detail: [STACK.md](./STACK.md), [FEATURES.md](./FEATURES.md), [ARCHITECTURE.md](./ARCHITECTURE.md), [PITFALLS.md](./PITFALLS.md).

## Key Findings

### Recommended Stack

Use **Supabase Swift** (repo resolves **2.43.1**; verify patch before each release) with **PostgREST** for `user_achievements` and optional `achievement_definitions`. **Postgres + RLS** is mandatory for exposed tables: SELECT/INSERT scoped to `auth.uid() = user_id`, no client UPDATE/DELETE on earned rows. **No Edge Functions or Realtime** required for v1. **Local cache:** extend `AppPersistence` / `UserDefaults` with per-`user_id` keys (e.g. `achievementsEarned.<userId>`). **UI:** SwiftUI-only celebrations (spring/scale/opacity, optional SF Symbol effects)—no Lottie, Game Center, or heavy particles. **Concurrency:** existing `async`/`await` + `ObservableObject` / `@Published`; no new reactive stack.

**Core technologies:**
- **Supabase Swift:** remote auth + PostgREST — matches lockfile and official patterns.
- **Postgres + RLS + unique constraint:** security and idempotent grants — Supabase standard; prevents duplicate rows and forged cross-user writes.
- **UserDefaults + Codable:** fast earned-set reads — consistent with app; skip Core Data/SwiftData for this small surface.
- **SwiftUI Animation:** minimalist unlock motion — first-party, on-brand.

### Expected Features

**Must have (table stakes):**
- Clear rule tying medals to the **same event** as official streak updates (post-`completeTask`).
- Tiered milestones with early wins; **durable** earned record (local + remote for signed-in users).
- **Journey** collection: locked vs unlocked, labels, progress toward next milestone.
- **Non-blocking** earn feedback (toast / haptic / short animation).
- Honest UX when streak breaks: current streak vs permanent medals.

**Should have (differentiators):**
- Permanent medals never revoked; minimalist number + ring/glow; contextual Journey section (not a separate “game” tab).
- Calm copy and framing on streak break (faith-sensitive tone).

**Defer (v2+):**
- Leaderboards, RPG economy, social sharing, widget medals, illustrated badge packs, multiple streak channels, notification-heavy milestone pushes (validate separately).

### Architecture Approach

Achievements are a **separate ledger** from the streak metric: `BibleTodoRepository` stays the streak source of truth; **`AchievementRepository`** + local cache hold earned facts; **`AchievementEvaluator`** is pure (streak + earned set → new slugs); **orchestration** lives in the service layer (**extend `BibleService` / `SupabaseBibleService`** — Pattern A recommended). **Critical seam:** `syncTaskCompletion` currently discards `StreakInfo` from `completeTask`; **consume that return value** to avoid an extra round trip. Presentation: `JourneyViewModel` for grid; `HomeViewModel` (or shared state) for edge-triggered toast once per completion.

**Major components:**
1. **`AchievementEvaluator`** — pure milestone logic; no I/O.
2. **`AchievementRepository`** — Supabase CRUD/sync for `user_achievements`; mirror `BibleTodoRepository` error patterns.
3. **Local achievement cache** — namespaced `UserDefaults`; merge remote on launch/sign-in.
4. **Service orchestration** — single evaluation choke point after successful `completeTask`.
5. **Journey + Home UI** — read models from cache/service; isolated failure domains.

### Critical Pitfalls

1. **Wrong streak truth** — Do not use `JourneyViewModel` merged preview for eligibility; use post-`completeTask` `StreakInfo` (or explicit post-sync summary).
2. **TOCTOU / double grant** — Enforce uniqueness in DB; `INSERT … ON CONFLICT DO NOTHING` (or equivalent); single call site; idempotent client.
3. **Stale cache / silent errors** — Define when toast fires vs optimistic local-only; avoid `try?` swallowing on new writes; align “permanent badge” policy with server ack if product requires it.
4. **Journey coupling** — Do not block Journey on badge fetch; lazy/parallel load; small fault boundary.
5. **Over-engineering** — Enum + `newlyUnlocked(previous:streak:)` + one persistence adapter; no generic rules DSL until a second dimension exists.

## Implications for Roadmap

Suggested phase structure aligns with dependency order (evaluator before UI), architecture build order, and pitfall phase mapping.

### Phase 1: Schema, RLS, and constraints
**Rationale:** Remote source of truth and security must exist before client assumes contracts.  
**Delivers:** `user_achievements` (+ optional `achievement_definitions`), RLS policies, `unique (user_id, achievement_slug)`, migration docs.  
**Addresses:** Durable remote record, table-stakes persistence expectations.  
**Avoids:** Pitfall 2 (weak uniqueness), Pitfall 6 (RLS/identity).

### Phase 2: Domain evaluator, local cache, and completion hook
**Rationale:** Pure logic and the completion seam are the integrity core; tests can run without full UI.  
**Delivers:** Milestone catalog (enum/structs), `AchievementEvaluator` + unit tests, `AppPersistence` keys, orchestration in `SupabaseBibleService` consuming `StreakInfo`, `BibleService` protocol + mock updates.  
**Addresses:** Evaluation on authoritative streak, single choke point, idempotent record path.  
**Uses:** STACK patterns for upsert/conflict; ARCHITECTURE Pattern A.  
**Avoids:** Pitfalls 1, 2, 3, 5 (wrong source, races, over-abstraction).

### Phase 3: Achievement repository and launch sync
**Rationale:** Wire PostgREST DTOs, fetch/merge on cold start and after auth; retry policy for failed remote writes.  
**Delivers:** `AchievementRepository`, launch/bootstrap merge `local ∪ remote`, sign-out cache clear.  
**Addresses:** Cross-device reinstall, offline lag handling policy.  
**Avoids:** Pitfalls 3, 7, 8 (stale merge, timezone doc, account switch leak).

### Phase 4: Journey UI, progress, and celebration
**Rationale:** Presentation depends on stable read models and events from prior phases.  
**Delivers:** Journey badge section, locked/unlocked, next-milestone progress, subtle toast/haptics, coalesced notifications if multiple tiers.  
**Addresses:** Collection, progress, earn feedback table stakes; minimalist differentiator.  
**Avoids:** Pitfalls 4, 9 (Journey jank, toast spam).

### Phase 5: QA, hardening, and parity
**Rationale:** Permanent badges make wrong grants costly; multi-device and offline need explicit scenarios.  
**Delivers:** Integration tests (repository conflict), mock/production parity for evaluator, scenarios for undo vs earned, slow-network and multi-tab checks.  
**Avoids:** Pitfall 10 (test drift).

### Phase Ordering Rationale

- **Schema before hook:** DB uniqueness and RLS are the backstop for races and retries.  
- **Evaluator before repository UI:** Keeps tests green and prevents logic sprawl in view models.  
- **Repository + sync before polish:** Journey and toast assume merge and retry semantics.  
- **UI last with fault isolation:** Protects the core habit loop from badge network failures.

### Research Flags

**Likely needing deeper research during planning:**
- **Toast vs server-ack policy** for permanent medals (product/legal tone + integrity tradeoff).
- **Notification strategy** for milestones (table stakes for some apps; may be anti-feature if overused).
- **Faith-sensitive copy** — validate with a small number of user interviews (FEATURES gap).

**Standard patterns (lighter research):**
- Supabase RLS + PostgREST insert/select (well-documented).
- SwiftUI celebration primitives (Apple docs).
- MVVM + repository split already present in repo.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Lockfile 2.43.1, Supabase + Apple docs; Context7 unavailable — versions cross-checked via releases/docs. |
| Features | MEDIUM | Strong category patterns; sources mix official help, blogs, and editorials; subjective “calm devotional” UX. |
| Architecture | HIGH | Grounded in `.planning/codebase/ARCHITECTURE.md` and actual `StreakInfo` / `syncTaskCompletion` seam. |
| Pitfalls | HIGH | Tied to known split-brain (Journey vs server) and distributed idempotency patterns. |

**Overall confidence:** **HIGH–MEDIUM** — implementation path is clear; product validation and toast/ack policy deserve explicit requirements.

### Gaps to Address

- **Competitive parity for calm medal UX:** Subjective; plan lightweight validation (interviews or design review).
- **Offline ordering:** Define single rule when local shows earned but remote lags (merge, retry, user-visible states).
- **iOS SDK vs `symbolEffect`:** Confirm APIs against deployment target in Xcode (STACK note).

## Sources

### Primary (HIGH confidence)
- [supabase-swift Releases (2.43.1)](https://github.com/supabase/supabase-swift/releases)
- [Supabase: Tables and Data](https://supabase.com/docs/guides/database/tables)
- [Supabase: Row Level Security](https://supabase.com/docs/guides/auth/row-level-security)
- [Apple: SwiftUI Animation](https://developer.apple.com/documentation/swiftui/animation)
- Repo: `Package.resolved` (Supabase pin), `.planning/PROJECT.md`, `.planning/codebase/ARCHITECTURE.md`, `.planning/codebase/CONCERNS.md`

### Secondary (MEDIUM confidence)
- [YouVersion — Streaks / Badges help](https://blog.youversion.com/) / support articles — habit and badge expectations
- [Hallow — Streaks FAQ](https://help.hallow.com/) — current vs longest, persistence framing
- [SwiftfulGamification](https://github.com/SwiftfulThinking/SwiftfulGamification), [gamification architecture write-up](https://thechosenvictor.com/blog/gamification-architecture) — layering corroboration (not dependency recommendations)
- Distributed idempotency / TOCTOU articles (see PITFALLS.md)

### Tertiary (LOW confidence — validate if cited for product claims)
- Editorial habit-app roundups, app store marketing, Stack Overflow cross-platform analogies — pattern hints only

---
*Research completed: 2026-04-12*  
*Ready for roadmap: yes*
