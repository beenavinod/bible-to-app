# Feature Landscape — Achievement / Gamification (Habit & Devotional Apps)

**Product:** Bible Life — streak-based medals/badges milestone  
**Researched:** 2026-04-12  
**Confidence:** **MEDIUM** — patterns synthesized from category leaders (YouVersion, Hallow), mainstream habit trackers (Streaks, Habitify, Habitica), and second‑party roundups; not a formal competitive teardown.

## How This Maps to Bible Life

- **Existing:** Daily verse + todo completion, `user_streaks` / `fetchStreakSummary`, Journey screen, completion path after `completeTask` (see `.planning/PROJECT.md`, `.planning/codebase/ARCHITECTURE.md`).
- **Planned milestone:** Tiered streak medals (e.g. 3 / 7 / 14 / 30 / 60 / 100 / 365 per PROJECT), permanent once earned, minimalist visuals, subtle earn feedback, local + Supabase persistence.

---

## Table Stakes

Features users broadly expect from streak + reward surfaces in habit and devotional apps. Omitting them tends to feel unfinished, confusing, or unfair.

| Feature | Why expected | Complexity | Notes |
|--------|----------------|------------|--------|
| **Visible current streak** | Primary feedback loop; users check “am I on track?” | Low | Bible Life already surfaces streaks in Journey; achievements sit on top of this. |
| **Clear rule for what counts as a day** | Prevents support churn and distrust (“I did it—why no streak?”) | Low–Med | Devotional apps often tie streaks to a *specific* completed action (e.g. Daily Refresh vs app open in YouVersion). Bible Life: tie medals to the same event as official streak updates (task completion). |
| **Milestone tiers with early wins** | Habit science + product: early reinforcement improves retention | Med | Category apps use small integers first (1, 3, 7…) before long horizons. PROJECT’s curve (3→365) matches this. |
| **Durable record of earned rewards** | “I lost my phone” / reinstall anxiety; medals feel cheap if they vanish | Med | YouVersion badges persist with account; Hallow stresses account-backed streak survival. Dual local + remote cache matches table stakes for signed-in apps. |
| **Collection / inventory view** | Users revisit progress; “trophy case” is the mental model | Low–Med | YouVersion badge list; StreakUp-style “hall of fame.” Bible Life: section on Journey fits this expectation. |
| **Locked vs unlocked affordance** | Users must see what exists and what’s next | Low | Silhouette / dimmed state + milestone label is standard. |
| **Progress toward next milestone** | Reduces opaque jumps (“why didn’t I get anything?”) | Med | Show “X days → next tier at Y” or partial progress bar. Depends on **accurate streak integer** after sync. |
| **Earn moment feedback (non-blocking)** | Without it, users miss the dopamine loop entirely | Low–Med | YouVersion explicitly calls out “mini-celebrations” at milestones. Toast / banner / haptic fits “devotional calm” better than full-screen RPG fanfare. |
| **Honest behavior on streak break** | If live streak resets, UI must not lie; permanent medals still need explanation | Med | Table stakes = clarity: current streak vs “best ever” vs “lifetime medals.” PROJECT’s **permanent medals** are a deliberate positioning choice (see Differentiators). |

**Dependencies (table stakes cluster):**

- Streak **definition** → drives **evaluation** → drives **unlock** → **persistence** → **collection UI** → **progress UI**.
- **Progress toward next milestone** depends on **Streak summary** (and agreed timezone / day boundary—already part of streak system).

---

## Differentiators

Not universally required; they sharpen positioning vs generic trackers or heavy gamification.

| Feature | Value proposition | Complexity | Notes |
|--------|-------------------|------------|--------|
| **Permanent medals (never revoked)** | Reduces shame spiral when streak breaks; honors cumulative effort | Med | Contrasts with “streak is everything” apps. Strong fit for spiritual/habit dignity; must be messaged clearly so it doesn’t look like a bug vs current streak. |
| **Minimalist medal aesthetic (number + ring/glow)** | Cohesive with calm devotional UX; avoids art pipeline | Low–Med | Differentiator vs illustrated badge sets (YouVersion-style rich badges). |
| **Single “Bible Life streak” channel** | Simplicity; one habit to protect | Low | Differentiator vs Habitica/RPG breadth—**scope choice**, not a feature users demand, but it keeps cognitive load low. |
| **Milestone pacing tuned to devotion (7 / 30 / 100 / year)** | Speaks the language of sustained practice | Low | PROJECT extends with 3 / 14 / 60 for smoother curve—good hybrid of “early win” + “serious commitment.” |
| **Contextual placement (Journey, not new tab)** | Reinforces narrative of spiritual journey vs “game lobby” | Low | Reduces navigation churn; differentiator vs standalone achievement tabs in game-like apps. |
| **Optional depth: “best streak” or history annotation** | Power users want credit for past peaks | Med | Hallow surfaces current + longest; habit apps emphasize stats. Nice phase-2 depth if MVP stays minimal. |
| **Restorative UX copy / framing** | When streak breaks, tone matters more in faith apps | Low | Not a widget; copy + empty states. High leverage, low engineering cost. |

**Dependencies:**

- **Permanent medals** require **immutable earn records** + **UI copy** that distinguishes *medal* vs *current streak*.
- **Minimal UI** pairs best with **subtle** celebrations (haptics, short toast)—avoid mismatch (minimal badges + loud confetti).

---

## Anti-Features

Deliberately **not** building (some already in PROJECT out-of-scope)—included here for requirements hygiene.

| Anti-feature | Why avoid | Build instead |
|--------------|-----------|----------------|
| **Leaderboards / public ranking** | Shifts motivation extrinsic; community moderation burden; misaligned with contemplative use | Private milestones only (PROJECT). |
| **Heavy RPG economy (XP, gold, loot)** | Segment split: some users love Habitica-style play; many devotional users find it trivializing | Keep rewards **symbolic** and **local to practice** (streak medals). |
| **Punitive loss of earned medals when streak breaks** | Trust killer; feels cruel in spiritual context | Permanent medals + honest current streak (PROJECT). |
| **Opaque or surprise achievements** | Anxiety (“what am I being graded on?”) | Fixed public tier list + predictable rules. |
| **Per-category achievement matrix (v1)** | Combinatorial explosion, sync edge cases, unclear primary habit | Single overall streak channel (PROJECT). |
| **Achievement spam / interruptive full-screen flows** | Breaks daily completion flow; notification fatigue | Subtle toast / inline celebration; respect focus. |
| **Social sharing as MVP** | Scope, moderation, privacy, design assets | Defer; optional later if brand-appropriate. |
| **Widget-level medal display (this milestone)** | Separate targets, caching, scope creep (PROJECT) | In-app Journey only for v1. |
| **Custom illustrated asset library requirement** | Blocks ship; design debt | Minimalist generative UI (PROJECT). |

---

## Focus Areas (Requirements Hooks)

### 1. Streak-based achievement tiers

- **Table stakes:** Monotonic tiers, visible list, evaluation on the **authoritative** streak update path (post-`completeTask` per PROJECT).
- **Differentiator:** Permanent unlock semantics + tier curve tuned for devotion (PROJECT’s 3/7/14/30/60/100/365).
- **Complexity:** Med (server schema + idempotent unlock + client cache).
- **Depends on:** Streak correctness, user id, clock/day boundary consistency.

### 2. Visual reward presentation

- **Table stakes:** Distinct unlocked vs locked; readable milestone label; accessible contrast / Dynamic Type.
- **Differentiator:** Minimal number + ring/glow consistent with app theme (PROJECT).
- **Complexity:** Low–Med (SwiftUI; optional lightweight animations).
- **Depends on:** Design tokens / existing Journey layout.

### 3. Unlock celebrations

- **Table stakes:** Some immediate feedback on first unlock of a tier.
- **Differentiator:** Restraint—**calm** celebration (toast, soft sound, haptic) vs game-style multi-step rewards.
- **Complexity:** Low–Med (orchestrate after successful sync path; avoid duplicate toasts on replay).
- **Depends on:** Reliable “newly earned” detection (diff vs last known set).

### 4. Progress indicators toward next milestone

- **Table stakes:** “Next badge at N days” or progress ring filled by `currentStreak / nextThreshold` (capped at 1 before unlock).
- **Differentiator:** Optional copy tying progress to spiritual habit (“day at a time”)—product voice, not mechanics.
- **Complexity:** Low for copy + static bar; Med if animated shared with widgets later (out of scope).
- **Depends on:** `fetchStreakSummary` (or equivalent) + ordered tier list.

---

## Feature Dependency Graph (Logical)

```
Streak definition & daily completion rule
        ↓
Authoritative streak value (local + server)
        ↓
Tier catalog (ordered thresholds)
        ↓
Evaluation / idempotent unlock
        ↓
Persistent earned set (local cache ↔ remote)
        ↓
├── Collection UI (Journey)
├── Locked/unlocked presentation
├── Unlock celebration (edge-triggered)
└── Next-milestone progress UI
```

---

## MVP vs Later (Research View)

**MVP (aligned with PROJECT):** tiers + permanent unlock + Journey section + subtle earn feedback + sync + next-milestone hint.

**Defer without losing category credibility:** sharing, leaderboards, multiple streak channels, illustrated badge packs, widget medals, RPG mechanics.

---

## Sources

| Source | Use | Confidence |
|--------|-----|------------|
| [YouVersion — Announcing Streaks](https://blog.youversion.com/2017/08/youversion-bible-app-announcing-streaks-2017/) | Milestone celebrations, streak as habit loop | MEDIUM (marketing blog; behavior still reflected in product) |
| [YouVersion Support — Streak](https://help.youversion.com/l/en/article/oyriuwt1fn-streak-android) | Multiple streak types, reminders, where streak surfaces | MEDIUM |
| [YouVersion Support — Badges](https://help.youversion.com/l/en/article/496aika6c5-badges-android) | Badge collection, milestone numbering, persistence expectations | MEDIUM |
| [Hallow — Streaks & Prayer Activity FAQ](https://help.hallow.com/en/articles/5761398-streaks-prayer-activity-faq) | Current vs longest streak, opt-out, account persistence | MEDIUM |
| [Knack — Must-have habit app features (2026 roundup)](https://www.knack.com/blog/best-habit-tracker-app/) | Progress visualization, reminders as category norms | LOW–MEDIUM (editorial) |
| [DEV — Habit tracker comparison (OpenHabitTracker vs Habitica, Streaks, …)](https://dev.to/jinjinov/openhabittracker-vs-habitica-loop-habit-tracker-streaks-and-everyday-1fp7) | Streak vs non-streak philosophies, gamification spectrum | LOW–MEDIUM |
| [StreakUp (Play Store listing)](https://play.google.com/store/apps/details?id=com.uifusion.streakup) | Badges + “hall of fame” pattern in gamified habit apps | LOW (store marketing) |

---

## Gaps / Phase-Specific Follow-Ups

- **Exact competitive parity** for “calm devotional” medal UX is subjective—validate with 3–5 user interviews (faith-sensitive tone).
- **Notification strategy:** reminders are table stakes for many apps; medal milestone pushes may be anti-feature if overused—treat as separate research item vs in-app-only celebrations.
- **Offline edge cases:** unlock when server lags—define single source of truth ordering (server wins vs optimistic UI).
