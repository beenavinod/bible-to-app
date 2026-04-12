# Requirements: Bible Life — Achievement System

**Defined:** 2026-04-12
**Core Value:** Users see tangible, permanent proof of their spiritual consistency — medals that persist even after a streak breaks.

## v1 Requirements

Requirements for initial release. Each maps to roadmap phases.

### Schema & Persistence

- [ ] **SCHM-01**: Achievement definitions stored with milestone thresholds (7, 30, 100 days) for each streak type (verse, todo)
- [ ] **SCHM-02**: User achievements persisted in a dedicated Supabase table with unique constraint on (user_id, achievement_slug) to prevent duplicates
- [ ] **SCHM-03**: Row Level Security enforces that users can only read/insert their own achievements (no update/delete)
- [ ] **SCHM-04**: Achievement state cached locally in UserDefaults per signed-in user for instant reads and offline resilience

### Evaluation & Integration

- [ ] **EVAL-01**: Achievement evaluation triggers only from the server-authoritative streak value (post-`completeTask` `StreakInfo`), not from local streak merge
- [ ] **EVAL-02**: Evaluator checks current streak against milestone thresholds and returns newly unlocked achievements (idempotent — already-earned medals are skipped)
- [ ] **EVAL-03**: Separate achievement tracks evaluate independently for Bible Verse streaks and Todo streaks
- [ ] **EVAL-04**: Achievement evaluation does not modify, slow down, or break the existing streak tracking or task completion flow
- [ ] **EVAL-05**: Single evaluation choke point in `SupabaseBibleService` after successful task sync — no duplicate call sites

### Achievement Behavior

- [ ] **ACHV-01**: Medals are permanent — once earned at a milestone, the medal persists even if the user's streak resets
- [ ] **ACHV-02**: Achievement grants use conflict-safe insert (INSERT ON CONFLICT DO NOTHING) to handle retries and multi-device scenarios without double-grants
- [ ] **ACHV-03**: On app launch and sign-in, local achievement cache merges with remote achievements (union of local and server sets)
- [ ] **ACHV-04**: On sign-out, local achievement cache is cleared for the departing user

### Presentation

- [ ] **PRES-01**: User can view a trophy/collection screen showing all available achievements with locked vs unlocked states
- [ ] **PRES-02**: Achievement collection is accessible from the Journey screen (not a separate tab)
- [ ] **PRES-03**: Each achievement displays the milestone tier (7, 30, 100), streak type (verse or todo), and earned date if unlocked
- [ ] **PRES-04**: User can see progress toward the next unearned milestone (e.g., "Day 12 of 30")
- [ ] **PRES-05**: When an achievement is newly earned, user sees a non-blocking celebration (toast/banner with haptic feedback)
- [ ] **PRES-06**: Achievement visuals use a minimalist design (number + ring/glow) consistent with the app's devotional aesthetic

### Protocol & Testing

- [ ] **TEST-01**: `BibleService` protocol extended with achievement methods; `MockBibleService` updated for previews and tests
- [ ] **TEST-02**: `AchievementEvaluator` is a pure function with unit tests covering all milestone thresholds, edge cases, and idempotency

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Extended Milestones

- **MILE-01**: Additional milestone tiers (3, 14, 60, 365 days) for a smoother progression curve
- **MILE-02**: "Best streak" or "longest streak" stat displayed alongside current streak

### Enhanced Presentation

- **ENPR-01**: Share achievement card to social media or save to photo library
- **ENPR-02**: Animated achievement detail view with richer visuals
- **ENPR-03**: Achievement widget on Home Screen showing latest earned medal

### Notifications

- **NOTF-01**: Push notification when user is close to a milestone (e.g., "1 day away from 30-day medal!")
- **NOTF-02**: Congratulatory push notification on achievement unlock

## Out of Scope

| Feature | Reason |
|---------|--------|
| Leaderboards or public ranking | Extrinsic motivation misaligned with contemplative use; moderation burden |
| XP / points / RPG economy | Trivializes spiritual practice; segment mismatch with devotional users |
| Medal revocation on streak break | Punitive; undermines motivational purpose (core design decision) |
| Per-category achievement matrix | Combinatorial explosion; unclear primary habit for v1 |
| Widget display of achievements | Widgets are still placeholder-only; separate concern |
| Custom illustrated badge assets | Blocks shipping; design debt — use minimalist generative UI instead |
| Push notifications for milestones | Separate notification infrastructure concern; defer |
| Social sharing of achievements | Scope, moderation, privacy — defer to v2+ |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| SCHM-01 | Phase 1 | Pending |
| SCHM-02 | Phase 1 | Pending |
| SCHM-03 | Phase 1 | Pending |
| SCHM-04 | Phase 2 | Pending |
| EVAL-01 | Phase 2 | Pending |
| EVAL-02 | Phase 2 | Pending |
| EVAL-03 | Phase 2 | Pending |
| EVAL-04 | Phase 2 | Pending |
| EVAL-05 | Phase 2 | Pending |
| ACHV-01 | Phase 2 | Pending |
| ACHV-02 | Phase 2 | Pending |
| ACHV-03 | Phase 2 | Pending |
| ACHV-04 | Phase 2 | Pending |
| PRES-01 | Phase 3 | Pending |
| PRES-02 | Phase 3 | Pending |
| PRES-03 | Phase 3 | Pending |
| PRES-04 | Phase 3 | Pending |
| PRES-05 | Phase 3 | Pending |
| PRES-06 | Phase 3 | Pending |
| TEST-01 | Phase 2 | Pending |
| TEST-02 | Phase 2 | Pending |

**Coverage:**
- v1 requirements: 21 total
- Mapped to phases: 21
- Unmapped: 0 ✓

---
*Requirements defined: 2026-04-12*
*Last updated: 2026-04-12 — roadmap: coarse 3-phase mapping (ACHV-03/04 folded into Phase 2 with repository/sync)*
