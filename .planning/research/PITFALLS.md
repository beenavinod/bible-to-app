# Domain Pitfalls — Achievement / Gamification on Existing iOS (Bible Life)

**Domain:** Streak-based, permanent milestone badges on an existing SwiftUI + Supabase app  
**Researched:** 2026-04-12  
**Context:** `.planning/PROJECT.md`, `.planning/codebase/CONCERNS.md`, `.planning/codebase/ARCHITECTURE.md`

## Critical Pitfalls

### Pitfall 1: Evaluating achievements from the wrong “streak truth” (local merge vs `user_streaks`)

**What goes wrong:** Badge unlock uses `JourneyViewModel`’s merged / recomputed streak (local `completedRecordIDs` + history) while the product rule is “server streak after successful `completeTask`.” Users see a Journey card that disagrees with Supabase (`CONCERNS.md`: Journey streak summary may diverge from server). Achievements then unlock from optimistic local math, or fail to unlock when the UI *looks* eligible—both erode trust.

**Why it happens:** The completion path already updates `user_streaks` in `BibleTodoRepository.completeTask`; Journey separately merges offline markers. Two pipelines, two answers.

**Consequences:** False unlocks (show badge the server would never grant), missed unlocks (user “earned” it in UI but server count lags), and support/debugging hell (“badge says 30, card says 28”).

**Prevention:**

- Treat **post-`completeTask` response** (or an explicit `fetchStreakSummary` immediately after a successful sync) as the **only** input for milestone evaluation—not `JourneyViewModel.recalculateSummary` output.
- Document one sentence in code: **achievements follow repository streak, not calendar merge preview.**
- If you must show a badge “pending sync,” make that a deliberate UX state—not a silent mismatch.

**Warning signs (detect early):**

- Unit tests mock streak from `MockBibleService` but production reads a different code path than `completeTask`.
- QA reports badge toast on flaky network same day as “streak didn’t update.”
- `user_streaks.current_streak` and Journey card differ in logs for the same session.

**Which phase should address it:** **Phase 2 — Repository & completion hook** (define evaluation input). **Phase 4 — Journey UI** (ensure display copy and badge section don’t imply a third streak definition).

---

### Pitfall 2: TOCTOU races and double grants (client retries, multi-device, concurrent completes)

**What goes wrong:** Pattern “read achievements → read streak → if eligible insert” is two round-trips. Two tabs, two devices, or a retry after timeout can both pass the check and insert duplicate rows—or show duplicate toasts if the client doesn’t dedupe.

**Why it happens:** Mobile networks retry; users double-tap; Swift concurrency makes overlapping `Task`s easy; Supabase PostgREST has no magic serialization across separate HTTP calls.

**Consequences:** Duplicate `user_achievements` rows (if uniqueness is weak), repeated notifications, ambiguous “source of truth” for analytics.

**Prevention:**

- **Database authority:** `(user_id, achievement_id)` unique constraint (or natural key). Inserts should be **`INSERT … ON CONFLICT DO NOTHING`** (or RPC that upserts once) so the second writer loses cleanly without throwing to the user.
- **Idempotent client:** Safe to call “record unlock” after every successful completion; server dedupes. Avoid “only if not in local array” as the *sole* guarantee.
- **Single evaluation choke point:** One function invoked from the success path after `completeTask`, not scattered in view models.

**Warning signs:**

- “Sometimes two toasts” on slow 3G simulators.
- Rare 409/unique violations bubbling as user-visible errors instead of silent no-ops.
- Achievement logic duplicated in `HomeViewModel` and `JourneyViewModel`.

**Which phase should address it:** **Phase 1 — Schema & RLS** (constraints). **Phase 2 — Repository hook** (single call site + conflict handling).

---

### Pitfall 3: False unlocks / false denials from stale reads (cache, launch order, silent `try?`)

**What goes wrong:** Badge check uses **cached** streak summary, **stale** `fetchStreakSummary` from before today’s write completes, or proceeds after a **swallowed error** (`try?` patterns noted in `CONCERNS.md`). User gets a badge without server streak reaching the threshold, or misses one while offline.

**Why it happens:** `PROJECT.md` asks to avoid extra network when badges already local—correct for performance, dangerous if “skip fetch” also skips **validation** on ambiguous state. Launch/bootstrap races (`resolveAppLaunchState` / `bootstrapSupabaseLaunch`) can leave the app in a state where local completion IDs exist but server streak lags.

**Consequences:** Permanent badges are **irreversible** by design—wrong grants are a product and integrity incident, not a toggle.

**Prevention:**

- **Tier local cache:** “Known earned” list can be read without network. **Eligibility** for *new* tiers should use **fresh streak from the same atomic completion response** or a follow-up read keyed to that completion’s success.
- **Explicit states:** `synced`, `pendingRemoteUnlock`, `knownRemote`—avoid boolean soup; only show toast on **confirmed** persist (local + remote policy below).
- **Surface write failures:** Achievement remote write should use the same seriousness as streak writes; if remote fails, queue retry and **do not** toast “earned” until you’ve chosen a rule (either optimistic toast with later correction—bad for permanent badges—or toast only after server ack).

**Warning signs:**

- Badge appears then disappears after next pull-to-refresh (if you ever add revocation— you won’t—or if UI reads two sources).
- Sentry/logs show `completeTask` OK but achievement insert never attempted.
- High `try?` density around sync in the new code path.

**Which phase should address it:** **Phase 2 — Repository hook** (ordering + error policy). **Phase 3 — Local cache & sync** (merge and retry/outbox). **Phase 5 — QA / hardening** (airplane mode, multi-device).

---

### Pitfall 4: Breaking existing streak UX by over-coupling Journey to achievements

**What goes wrong:** Journey load now blocks on achievement fetch; calendar scroll stutters; or failure in `user_achievements` empty-states the whole Journey tab. Achievement sync errors reuse the “silent empty” pattern from `HomeViewModel.load`.

**Why it happens:** New feature piggybacks on `JourneyViewModel.load` without isolating faults; heavy work on main actor; N+1 queries for seven milestones.

**Consequences:** Regressions in core habit loop—worse than “badges shipped late.”

**Prevention:**

- **Fault isolation:** Badges section fails small (placeholder or last-known-good cache), streak history and calendar stay up.
- **Lazy fetch:** Load badges after streak/history or in parallel with **independent** error handling.
- **Performance budget:** No extra full-table scans; seven fixed keys are O(1) per user.

**Warning signs:**

- Instruments shows Journey scene phase tied to new network await.
- Users on slow networks report blank Journey where only badges failed.

**Which phase should address it:** **Phase 4 — Journey UI & toast** (composition and error boundaries). **Phase 3** if fetch strategy lives in VM/repository.

---

### Pitfall 5: Over-engineering the “achievement engine”

**What goes wrong:** Generic rules engine, DSL, admin console, event bus, or “future-proof” plugin architecture for **seven static thresholds** on **one** dimension (overall streak). Weeks disappear; edge cases multiply; tests never cover real `completeTask` ordering.

**Why it happens:** Second-system effect; copying patterns from large games or BaaS products.

**Consequences:** Late ship, hard review, and more surface for races (multiple subscribers firing unlock).

**Prevention:**

- **Start with:** `enum Milestone: Int { case three = 3 … }`, a pure function `newlyUnlocked(previous: Set<Milestone>, streak: Int) -> [Milestone]`, and a single persistence adapter. Add abstraction only when a **second dimension** (e.g. category) is in scope per `PROJECT.md` out-of-scope list.
- **Test matrix:** Property-style tests on the pure function + integration test on repository mock for conflict/duplicate.

**Warning signs:**

- First PR introduces “AchievementRuleProtocol” and more than one implementation.
- Unlock logic not callable from a single line after `completeTask`.

**Which phase should address it:** **Phase 2** (keep core dumb). **Phase 5** (refactor gate—only if requirements change).

---

## Moderate Pitfalls

### Pitfall 6: RLS and identity assumptions

**What goes wrong:** Achievements table readable/writable across users; or dev forgets `user_id` match on insert. Client-only checks are bypassable with anon key (expected Supabase model—server must enforce).

**Prevention:** RLS policies mirror `user_streaks` / `user_tasks`; inserts only for `auth.uid() = user_id`. **Phase 1.**

### Pitfall 7: Clock / timezone off-by-one for “day”

**What goes wrong:** Badge evaluated with device date vs server `assigned_date` boundaries; traveler changes timezone; streak appears to jump.

**Prevention:** Reuse `BibleTodoDate` and the same “day” definition as streak assignment. Document that milestones are **streak count**, not calendar days. **Phase 2.**

### Pitfall 8: Sign-out / account switch leaking badge cache

**What goes wrong:** `UserDefaults` cache shows previous user’s badges until overwritten.

**Prevention:** Clear achievement cache on sign-out in the same place daily cache clears (`AppState` / repository). **Phase 3.**

---

## Minor Pitfalls

### Pitfall 9: Toast spam and navigation interrupts

**What goes wrong:** Multiple milestones crossed in one logical fix (backfill) or test harness fires three toasts.

**Prevention:** Coalesce per session; or one toast with “3 new milestones” copy. **Phase 4.**

### Pitfall 10: Preview and tests drifting from production

**What goes wrong:** `MockBibleService` encodes achievement rules that diverge from Supabase path (`ARCHITECTURE.md` notes tests only cover mock achievement rules).

**Prevention:** Share the pure `newlyUnlocked` function between app and tests; add one repository-level test with conflict. **Phase 5.**

---

## Phase-Specific Warnings (recommended mapping)

| Phase focus | Likely pitfall | Mitigation |
|-------------|----------------|------------|
| **Phase 1 — Schema & RLS** | Weak uniqueness → duplicates | Unique constraint + conflict-safe insert/RPC |
| **Phase 2 — Repository & completion hook** | Wrong streak source / ordering | Evaluate from post-`completeTask` truth; single call site |
| **Phase 3 — Local cache & sync** | Optimistic false toasts; stale merge | Outbox/retry; clear rules for when toast fires |
| **Phase 4 — Journey UI & toast** | Journey regressions / jank | Isolate failures; lazy or parallel fetch |
| **Phase 5 — QA & hardening** | Offline, multi-device, undo | Scenarios for `undoTaskCompletion` vs already-earned permanent badges |

**Note:** Phase numbers are placeholders until `ROADMAP.md` exists—rename to match your actual phase IDs.

---

## Bible Life–Specific Tie-In (do not ignore)

1. **Known split-brain:** `JourneyViewModel` merge vs `user_streaks` (`CONCERNS.md`) makes “display streak” the wrong default for **eligibility** unless you explicitly choose local-first product rules (you should not, without legal/product sign-off).
2. **Silent failure culture:** Broad `try?` on sync (`CONCERNS.md`) will reproduce for achievements unless new writes are instrumented.
3. **Permanent badges:** Over-granting is permanent; prefer **server-enforced idempotency** over client optimism.
4. **Widgets:** Out of scope for badge display (`PROJECT.md`)—don’t block achievement work on widget architecture, but don’t use widget placeholders as streak truth either.

---

## Sources

| Topic | Source | Confidence |
|-------|--------|------------|
| Check-then-act / distributed races | [Handling race conditions in distributed systems (Medium, 2026)](https://medium.com/@balkrishnadixit56/handling-race-conditions-in-distributed-systems-lessons-from-a-multiplayer-engine-9a5096be67e0) | MEDIUM (general pattern) |
| TOCTOU, idempotency, `INSERT ON CONFLICT` | [Dzone — Phantom write / idempotency failures](https://dzone.com/articles/phantom-write-idempotency-data-loss) | MEDIUM |
| Client cache + sync when offline / signed out | [Stack Overflow — Play Games achievements offline](https://stackoverflow.com/questions/31787861/handling-google-play-game-achievements-when-player-isnt-logged-in) | LOW (platform differs; pattern applies) |
| Project architecture, streak paths, concerns | `.planning/codebase/ARCHITECTURE.md`, `.planning/codebase/CONCERNS.md`, `.planning/PROJECT.md` | HIGH |

---

*Pitfalls research for achievement milestone — 2026-04-12*
