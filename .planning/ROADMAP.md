# Roadmap: Bible Life — Achievement System

## Overview

Ship a permanent streak-milestone medal layer on the existing Bible Life app: secure Supabase storage first, then a single service choke point that evaluates authoritative streaks after task completion with local cache and cross-device merge, and finally Journey-integrated collection UI with progress and subtle celebrations—without breaking the current habit loop.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Remote schema & security** — Supabase achievements table, definitions, RLS, and uniqueness guarantees
- [ ] **Phase 2: Evaluation engine, persistence & sync** — Pure evaluator, local cache, repository, service hook after `completeTask`, launch/sign-in merge and sign-out clear, protocol + tests
- [ ] **Phase 3: Journey collection & celebrations** — Trophy section on Journey, locked/unlocked, progress, minimalist visuals, earn toast/haptics

## Phase Details

### Phase 1: Remote schema & security
**Goal**: Remote source of truth exists for earned achievements with correct security and idempotency guarantees before the client depends on contracts.
**Depends on**: Nothing (first phase)
**Requirements**: SCHM-01, SCHM-02, SCHM-03
**Success Criteria** (what must be TRUE):
  1. Achievement definitions for verse and todo streaks exist with the agreed milestone thresholds (7, 30, 100 days per SCHM-01).
  2. A signed-in user can only read and insert their own achievement rows; they cannot read or modify another user's rows (RLS).
  3. The database enforces at most one earned row per user per achievement slug, so retries and parallel clients cannot create duplicates.
**Plans**: TBD

Plans:
- [ ] 01-01: Migrations — `user_achievements` (and definitions if separate), unique `(user_id, achievement_slug)`, no client update/delete on earned facts
- [ ] 01-02: RLS policies — SELECT/INSERT scoped to `auth.uid() = user_id`; document verification steps

### Phase 2: Evaluation engine, persistence & sync
**Goal**: After task sync, authoritative streak drives idempotent medal evaluation; medals persist locally and remotely, merge on launch/sign-in, and clear on sign-out—without changing existing streak or completion behavior.
**Depends on**: Phase 1
**Requirements**: SCHM-04, EVAL-01, EVAL-02, EVAL-03, EVAL-04, EVAL-05, ACHV-01, ACHV-02, ACHV-03, ACHV-04, TEST-01, TEST-02
**Success Criteria** (what must be TRUE):
  1. Completing a task still updates streaks as today; the user perceives no slowdown or failure in the hold-to-complete flow (EVAL-04).
  2. When the server-authoritative streak crosses a threshold, newly eligible medals are detected once; already-earned medals are never proposed again; evaluation runs from a single post-sync choke point in the service (EVAL-01, EVAL-02, EVAL-05).
  3. Verse streak and todo streak milestones evaluate independently—earning one track does not block the other (EVAL-03).
  4. Earned medals remain stored as facts even if the user's current streak later drops; grants use conflict-safe inserts for retries and multi-device (ACHV-01, ACHV-02).
  5. On app launch and sign-in, local cached medals union with remote; on sign-out, the departing user's local achievement cache is cleared; previews and tests exercise `BibleService` achievement surfaces and pure evaluator thresholds and idempotency without requiring ad-hoc production data (ACHV-03, ACHV-04, SCHM-04, TEST-01, TEST-02).
**Plans**: TBD

Plans:
- [ ] 02-01: `AchievementEvaluator` + unit tests; extend `AppPersistence` / UserDefaults cache per user
- [ ] 02-02: `AchievementRepository` + conflict-safe remote writes; merge policy on bootstrap
- [ ] 02-03: `SupabaseBibleService` single choke point after successful `completeTask` using returned `StreakInfo`; `BibleService` + mock updates

### Phase 3: Journey collection & celebrations
**Goal**: Users discover and understand their medals from Journey with clear locked/unlocked, progress to next tier, and a calm moment of recognition when something new unlocks.
**Depends on**: Phase 2
**Requirements**: PRES-01, PRES-02, PRES-03, PRES-04, PRES-05, PRES-06
**Success Criteria** (what must be TRUE):
  1. User can open a trophy/collection experience from the Journey screen without a new tab bar item (PRES-01, PRES-02).
  2. User sees every achievement as locked or unlocked; unlocked entries show milestone tier, verse vs todo type, and earned date when available (PRES-03).
  3. User sees progress toward the next unearned milestone (e.g. "Day 12 of 30") (PRES-04).
  4. When a medal is newly earned, the user gets a non-blocking celebration (toast or banner) with haptic feedback (PRES-05).
  5. Achievement visuals use minimalist number + ring/glow consistent with the app's devotional look (PRES-06).
**Plans**: TBD
**UI hint**: yes

Plans:
- [ ] 03-01: Journey section — grid/list, locked vs unlocked, tier/type/date, progress copy; fault-tolerant loading
- [ ] 03-02: Earn moment — toast/banner, haptics, coalesce if multiple tiers; minimalist styling pass

## Progress

**Execution Order:**
Phases execute in numeric order: 2 → 2.1 → 2.2 → 3 → 3.1 → 4

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Remote schema & security | 0/2 | Not started | - |
| 2. Evaluation engine, persistence & sync | 0/3 | Not started | - |
| 3. Journey collection & celebrations | 0/2 | Not started | - |

---
*Roadmap created: 2026-04-12 — coarse granularity (3 phases)*
