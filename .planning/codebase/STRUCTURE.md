# Codebase Structure

**Analysis Date:** 2026-04-12

## Directory Layout

```
bible-to-app/
├── BIBLE TODO/                    # Main iOS app target (SwiftUI)
├── BIBLE TODOTests/               # Unit tests (Swift Testing)
├── BIBLE TODOUITests/             # UI tests
├── Config/                        # xcconfig for Supabase build-time injection
├── LockScreenIconWidget/          # Widget extension: lock screen accessory
├── StreakWidget/                  # Widget extension: streak + control + live activity
├── VerseTaskWidget/               # Widget extension: verse + task
├── BIBLE TODO.xcodeproj/          # Xcode project, schemes, SwiftPM resolution
└── .planning/codebase/            # Architecture notes (this tree)
```

## Directory Purposes

**`BIBLE TODO/`:**
- Purpose: All production SwiftUI application source, `Info.plist`, and `Assets.xcassets`.
- Contains: App entry, global state, views, view models, Supabase integration, domain models, shared components.
- Key files: `BIBLE TODO/BIBLE_TODOApp.swift`, `BIBLE TODO/AppState.swift`, `BIBLE TODO/ContentView.swift`, `BIBLE TODO/Services.swift`, `BIBLE TODO/ViewModels.swift`, `BIBLE TODO/Models.swift`, `BIBLE TODO/BibleTodoRepository.swift`, `BIBLE TODO/SupabaseBibleService.swift`, `BIBLE TODO/BibleTodoSupabaseModels.swift`, `BIBLE TODO/SupabaseConfig.swift`, `BIBLE TODO/Info.plist`

**`Config/`:**
- Purpose: Shared xcconfig consumed as the app target’s `baseConfigurationReference` in `BIBLE TODO.xcodeproj/project.pbxproj`.
- Contains: `Config/AppConfig.xcconfig` (defaults + `#include? "Secrets.xcconfig"`), `Config/Secrets.example.xcconfig` (template for local secrets; real `Secrets.xcconfig` is not committed per template comments).

**`StreakWidget/`, `VerseTaskWidget/`, `LockScreenIconWidget/`:**
- Purpose: WidgetKit extension targets; each folder is one Xcode target’s sources plus `Info.plist` and `Assets.xcassets`.
- Contains: `*Bundle.swift` (`@main`), primary `*.swift` widget/live activity/control definitions, optional `AppIntent.swift` scaffolding.

**`BIBLE TODOTests/`:**
- Purpose: Unit tests with `@testable import BIBLE_TODO`.
- Key files: `BIBLE TODOTests/BIBLE_TODOTests.swift`

**`BIBLE TODOUITests/`:**
- Purpose: XCTest UI test target scaffolding.
- Key files: `BIBLE TODOUITests/BIBLE_TODOUITests.swift`, `BIBLE TODOUITests/BIBLE_TODOUITestsLaunchTests.swift`

**`BIBLE TODO.xcodeproj/`:**
- Purpose: Targets, build settings, file references, embedded extensions, Swift Package dependency on Supabase.
- Key files: `BIBLE TODO.xcodeproj/project.pbxproj`, `BIBLE TODO.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`, shared schemes under `BIBLE TODO.xcodeproj/xcshareddata/xcschemes/` (e.g. `BIBLE TODO.xcscheme`, `StreakWidgetExtension.xcscheme`, `VerseTaskWidgetExtension.xcscheme`, `LockScreenIconWidgetExtension.xcscheme`)

## Key File Locations

**Entry Points:**
- `BIBLE TODO/BIBLE_TODOApp.swift`: `@main` application.
- `StreakWidget/StreakWidgetBundle.swift`: widget bundle `@main`.
- `VerseTaskWidget/VerseTaskWidgetBundle.swift`: widget bundle `@main`.
- `LockScreenIconWidget/LockScreenIconWidgetBundle.swift`: widget bundle `@main`.

**Configuration:**
- `Config/AppConfig.xcconfig`, `Config/Secrets.example.xcconfig`
- `BIBLE TODO/Info.plist`: display name `Bible Life`, `SUPABASE_*` keys, `UIBackgroundModes` / photo library usage string

**Core Logic:**
- `BIBLE TODO/AppState.swift`: session, root phase, service wiring, settings mutations.
- `BIBLE TODO/BibleTodoRepository.swift`: Supabase data access and daily cache.
- `BIBLE TODO/ViewModels.swift`: feature view models.
- `BIBLE TODO/Models.swift`: shared UI/domain structs and theme enums.

**Testing:**
- `BIBLE TODOTests/BIBLE_TODOTests.swift`
- `BIBLE TODOUITests/` (UI)

## Naming Conventions

**Files:**
- SwiftUI screens and flows: descriptive `PascalCase` matching primary type (`HomeView.swift`, `OnboardingFlowView.swift`).
- Aggregated types: plural or role names (`ViewModels.swift`, `Models.swift`, `Services.swift`, `Components.swift`).
- Xcode target folder `BIBLE TODO` uses a space; module/product name for tests is `BIBLE_TODO` (underscore) as in `@testable import BIBLE_TODO`.

**Directories:**
- One top-level folder per Xcode target (`BIBLE TODO`, widget extension folders, test folders).
- `Config/` for xcconfig only.

**Swift symbols:**
- App struct: `BIBLE_TODOApp` (underscore in type name).
- Widget timeline providers: each extension defines `struct Provider: TimelineProvider` in its own module (no cross-file collision).
- Widget kinds: string literals on structs, e.g. `"StreakWidget"` in `StreakWidget/StreakWidget.swift`.

## Where to Add New Code

**New Feature (in-app screen):**
- Primary code: `BIBLE TODO/` — add a `*View.swift`; if non-trivial, add or extend a type in `BIBLE TODO/ViewModels.swift` (or a dedicated `*ViewModel.swift` if the project later splits files).
- Wire navigation: typically `BIBLE TODO/ContentView.swift` or parent view; pass `environmentObject(appState)` as existing screens do.

**New API / Supabase table access:**
- Add queries and DTOs in `BIBLE TODO/BibleTodoRepository.swift` and `BIBLE TODO/BibleTodoSupabaseModels.swift`; expose to UI through `BibleService` in `BIBLE TODO/Services.swift` and `BIBLE TODO/SupabaseBibleService.swift`.

**New persisted local preference:**
- Extend `AppPersistence` and `UserDefaultsPersistence` in `BIBLE TODO/Services.swift`; mirror in `PreviewPersistence` for previews; add `@Published` fields and setters on `BIBLE TODO/AppState.swift` if global.

**New widget or extension UI:**
- Add Swift files under the appropriate extension folder (`StreakWidget/`, `VerseTaskWidget/`, `LockScreenIconWidget/`) and register in the corresponding `*Bundle.swift`.

**Tests:**
- Unit: new `@Test` functions or files under `BIBLE TODOTests/`.
- UI: `BIBLE TODOUITests/`.

## Special Directories

**`BIBLE TODO.xcodeproj/xcuserdata/`:**
- Purpose: Per-developer Xcode state (schemes, UI state).
- Generated: By Xcode per machine.
- Committed: Often partially; user-specific files may appear in git status — treat as local IDE artifacts.

**`Assets.xcassets` (under each target):**
- Purpose: Images, accent colors, widget backgrounds.
- Generated: No (author-maintained).
- Committed: Yes.

---

*Structure analysis: 2026-04-12*
