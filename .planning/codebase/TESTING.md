# Testing Patterns

**Analysis Date:** 2026-04-12

## Test Framework

**Runner:**
- **Xcode** test action drives all tests; targets are defined in `BIBLE TODO.xcodeproj/project.pbxproj`.

**Unit tests:**
- **Swift Testing** (`import Testing`) in `BIBLE TODOTests/BIBLE_TODOTests.swift`.
- Tests use **`@Test`** functions and **`#expect`** macros (not `XCTestCase` / `XCTAssert` in that file).

**UI tests:**
- **XCTest** with **`XCUIApplication`** in `BIBLE TODOUITests/BIBLE_TODOUITests.swift` and `BIBLE TODOUITests/BIBLE_TODOUITestsLaunchTests.swift`.

**Assertion library:**
- Swift Testing: **`#expect`**.
- UI tests: **`XCTAssertTrue`**, **`measure`**, **`XCTAttachment`**.

**Run commands:**
```bash
# From repo root (scheme name includes a space)
xcodebuild test -scheme "BIBLE TODO" -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BIBLE\ TODOTests
xcodebuild test -scheme "BIBLE TODO" -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BIBLE\ TODOUITests
```
Adjust **`-destination`** to an installed Simulator or device. Scheme selection can also be done in Xcode (**Product → Test**).

## Test File Organization

**Location:**
- **Unit:** `BIBLE TODOTests/` — synchronized group in Xcode (`fileSystemSynchronizedGroups` in `project.pbxproj`).
- **UI:** `BIBLE TODOUITests/`.

**Naming:**
- Unit: `BIBLE_TODOTests.swift` (matches target `BIBLE TODOTests`).
- UI: `BIBLE_TODOUITests.swift`, `BIBLE_TODOUITestsLaunchTests.swift`.

**Structure:**
```
BIBLE TODOTests/
└── BIBLE_TODOTests.swift
BIBLE TODOUITests/
├── BIBLE_TODOUITests.swift
└── BIBLE_TODOUITestsLaunchTests.swift
```

**Test plan files:**
- No `.xctestplan` files detected in the repo.

## Test Structure

**Suite organization (Swift Testing):**

```swift
import Testing
@testable import BIBLE_TODO

@MainActor
@Test func mockBibleServiceProvidesHistoryAndTodayVerse() async throws {
    // ...
}
```

Reference: `BIBLE TODOTests/BIBLE_TODOTests.swift`.

**Patterns:**
- **`@MainActor`** on async tests that exercise main-actor–isolated APIs or types used from the UI module.
- **`async throws`** when calling **`async throws`** service methods (`fetchTodayVerse`, etc.).

**UI test patterns:**
- **`setUpWithError`**: `continueAfterFailure = false` (`BIBLE TODOUITests/BIBLE_TODOUITests.swift`).
- **`@MainActor`** on test methods that touch UI.
- **Launch tests** class sets `runsForEachTargetApplicationUIConfiguration` and attaches screenshots (`BIBLE TODOUITests/BIBLE_TODOUITestsLaunchTests.swift`).

## Mocking

**Framework:** No third-party mocking library (no Mockito-style dependency).

**Patterns:**
- **Production mock** for tests and previews: **`MockBibleService`** conforms to **`BibleService`** and lives in `BIBLE TODO/Services.swift` (same file documents it is for **unit tests** and **SwiftUI previews** only).
- **Protocol-based** substitution: tests depend on **`BibleService`** behavior without a live Supabase stack.

```swift
let service = MockBibleService()
let todayVerse = try await service.fetchTodayVerse()
```

**What to mock:**
- **`BibleService`** for logic that only needs deterministic verse/history/streak data.
- **`AppPersistence`** can be swapped with **`PreviewPersistence`** or a test double for settings-heavy code (no dedicated test double file yet — follow `PreviewPersistence` in `BIBLE TODO/Services.swift` as an in-memory pattern).

**What NOT to mock:**
- Prefer real **value types** (`Achievement`, `StreakSummary`) for pure logic tests where no I/O is involved (see achievement test in `BIBLE TODOTests/BIBLE_TODOTests.swift`).

## Fixtures and Factories

**Test data:**
- **`MockBibleService.makeRecords()`** builds a fixed set of **`DailyRecord`** values with controlled completion flags and dates (`BIBLE TODO/Services.swift`).
- **`Achievement.defaults`** static array on `Achievement` (`BIBLE TODO/Models.swift`) used by tests for unlock thresholds.

**Location:**
- Inline in **`MockBibleService`**; shared model defaults in **`Models.swift`**.

## Coverage

**Requirements:** No **`CODE_COVERAGE`** or **`GatherCoverageData`** build settings found in `BIBLE TODO.xcodeproj/project.pbxproj` — coverage is **not enforced** in project settings.

**View coverage in Xcode:**
- **Product → Scheme → Edit Scheme → Test → Options → Code Coverage** (enable per developer machine / CI as needed).

**Prescriptive guidance:**
- When enabling coverage, include the **`BIBLE TODO`** app target and run **`BIBLE TODOTests`**; prioritize `BibleTodoRepository`, view models, and auth/bootstrap paths.

## Test Types

**Unit tests:**
- **Target:** `BIBLE TODOTests` — `com.apple.product-type.bundle.unit-test` in `project.pbxproj`.
- **Host:** The unit test bundle is **app-hosted**: `TEST_HOST` and `BUNDLE_LOADER` point at the built **`BIBLE TODO.app`** (`BIBLE TODO.xcodeproj/project.pbxproj`). This loads the app executable when running tests even though tests use `@testable import`.

**Integration tests:**
- Not separated as a distinct target; Supabase-backed flows are exercised manually or via UI tests, not via dedicated integration test targets in-repo.

**E2E tests:**
- **`BIBLE TODOUITests`** drives the full app: taps tab bar buttons and asserts on static text (`BIBLE TODOUITests/BIBLE_TODOUITests.swift`).
- **Performance:** `testLaunchPerformance` uses **`XCTApplicationLaunchMetric`** in the same file.

**Widget / extension tests:**
- **No** dedicated test targets for `StreakWidgetExtension`, `VerseTaskWidgetExtension`, or `LockScreenIconWidgetExtension` in `project.pbxproj`.

## Common Patterns

**Async testing (Swift Testing):**

```swift
@Test func mockBibleServiceProvidesHistoryAndTodayVerse() async throws {
    let service = MockBibleService()
    let todayVerse = try await service.fetchTodayVerse()
    let history = try await service.fetchHistory()
    #expect(history.contains(where: { $0.verse.id == todayVerse.id }))
}
```

**Pure logic testing:**

```swift
@Test func achievementsUnlockAgainstCurrentStreak() {
    let cross = Achievement.defaults[0]
    #expect(cross.isUnlocked(for: 3))
}
```

**UI existence checks:**

```swift
XCTAssertTrue(app.staticTexts["TODAY'S ACTION"].waitForExistence(timeout: 2))
```

## Testability of main target

**`ENABLE_TESTABILITY`:** Set to **YES** on the **`BIBLE TODO`** debug configuration in `project.pbxproj`, allowing **`@testable import BIBLE_TODO`** from `BIBLE TODOTests/BIBLE_TODOTests.swift`.

---

*Testing analysis: 2026-04-12*
