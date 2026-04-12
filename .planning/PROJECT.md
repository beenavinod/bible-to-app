# Bible Life — Achievement System

## What This Is

An achievement system for the Bible Life iOS app that rewards users with persistent, collectible badges when they hit streak milestones (3, 7, 14, 30, 60, 100, and 365 days). Badges are earned once, displayed in a new section within the existing Journey screen, and stored both locally and in Supabase so they survive reinstalls and device changes.

## Core Value

Users feel recognized and motivated to maintain their daily Bible verse and task habit through visible, permanent milestone badges.

## Requirements

### Validated

- ✓ Daily verse and task system — existing (`SupabaseBibleService`, `BibleTodoRepository`)
- ✓ Streak tracking — existing (`user_streaks` table, `fetchStreakSummary` in `BibleService`)
- ✓ Task completion flow — existing (hold-to-complete in `HomeViewModel`, syncs via `completeTask`)
- ✓ Journey screen with streak history — existing (`JourneyView`, `JourneyViewModel`)
- ✓ Local persistence layer — existing (`UserDefaultsPersistence`, `AppPersistence` protocol)
- ✓ Supabase remote persistence — existing (`BibleTodoRepository`)

### Active

- [ ] Badge data model with 7 milestone tiers (3, 7, 14, 30, 60, 100, 365 days)
- [ ] Badge evaluation logic that checks streak against milestones on task completion
- [ ] Persistent badge storage in Supabase (new table) and local cache (UserDefaults)
- [ ] Badge display section in the Journey screen (minimalist style with number and glow/ring)
- [ ] Subtle toast notification when a badge is earned
- [ ] Badges are permanent — earned once, never revoked even if streak breaks
- [ ] Hook into existing streak tracking without breaking current completion flow
- [ ] Sync badges between local and remote on app launch and task completion

### Out of Scope

- Widget badge display — widgets stay as-is; badges are in-app only
- Per-category achievements — badges track overall daily streak only, not per Bible Life category
- Custom illustrated medal assets — using minimalist style (number + subtle glow/ring)
- Social sharing of badges — not in this milestone
- Leaderboards or competitive features — not in this milestone
- Non-streak achievements (e.g., first task, shared a card) — future consideration

## Context

- **Existing app:** Bible Life is a SwiftUI iOS app with Supabase backend. Users receive a daily Bible verse with a related todo task. They mark tasks done to build streaks.
- **Architecture:** Protocol-based (`BibleService`, `AppPersistence`), repository pattern (`BibleTodoRepository`), MVVM with `HomeViewModel` and `JourneyViewModel`.
- **Streak logic lives in:** `BibleTodoRepository` (Supabase `user_streaks` table), surfaced through `BibleService.fetchStreakSummary()`, and displayed in `JourneyViewModel`.
- **Task completion path:** `HomeViewModel` hold-to-complete → `service.syncTaskCompletion` → `repository.completeTask` → updates `user_tasks` and `user_streaks`.
- **The achievement check point** is after a successful task completion updates the streak — that's where badge evaluation should hook in.
- **Local persistence** uses `UserDefaults` via `AppPersistence` protocol; remote uses Supabase PostgREST.

## Constraints

- **Tech stack**: Swift/SwiftUI + Supabase — must use existing patterns and protocols
- **Non-breaking**: Must not alter existing streak tracking behavior; achievement logic is additive
- **Persistence**: Dual storage (UserDefaults local cache + Supabase `user_achievements` table) for resilience
- **Performance**: Badge check on task completion must be lightweight — no extra network calls if badge already earned locally
- **Visual style**: Minimalist — milestone number with subtle glow or ring effect, consistent with existing app themes

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Badges earned once, permanent | Avoids punishing users for breaking streaks; rewards past effort | — Pending |
| Overall streak only (not per-category) | Keeps scope tight; categories add combinatorial complexity | — Pending |
| Journey screen placement (not new tab) | Keeps streak-related content together; avoids tab bar changes | — Pending |
| Dual persistence (local + Supabase) | Fast display from local cache; survives reinstall via remote | — Pending |
| Minimalist badge style | Consistent with existing app aesthetic; no asset design dependency | — Pending |
| Subtle toast for earning moment | Non-intrusive; doesn't interrupt daily flow | — Pending |
| 7 milestone tiers (3/7/14/30/60/100/365) | Progressive reward curve from early wins to long-term commitment | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-04-12 after initialization*
