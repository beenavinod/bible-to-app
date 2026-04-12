# Technology Stack

**Analysis Date:** 2026-04-12

## Languages

**Primary:**
- Swift 5 — all application, widget extension, and test source under `BIBLE TODO/`, `StreakWidget/`, `VerseTaskWidget/`, `LockScreenIconWidget/`, `BIBLE TODOTests/`, and `BIBLE TODOUITests/`.

**Secondary:**
- Not applicable (no scripting layer or secondary app language in-repo).

## Runtime

**Environment:**
- iOS (device and Simulator) — deployment target is set in `BIBLE TODO.xcodeproj/project.pbxproj` as `IPHONEOS_DEPLOYMENT_TARGET = 26.4` for project and targets.

**Package Manager:**
- Swift Package Manager (Xcode-integrated) — direct dependency declared in `BIBLE TODO.xcodeproj/project.pbxproj` (`XCRemoteSwiftPackageReference` for `supabase-swift`).
- Lockfile: `BIBLE TODO.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` (pins resolved revisions and versions).

## Frameworks

**Core:**
- SwiftUI — primary UI (`BIBLE TODO/BIBLE_TODOApp.swift`, views across `BIBLE TODO/`).
- Combine — reactive state in `BIBLE TODO/ViewModels.swift` and `BIBLE TODO/AppState.swift`.
- WidgetKit + SwiftUI — widget extensions in `StreakWidget/`, `VerseTaskWidget/`, `LockScreenIconWidget/`.
- AppIntents — control/intent surfaces in each extension’s `AppIntent.swift` and `*Control.swift` files.
- ActivityKit + WidgetKit + SwiftUI — Live Activities in `StreakWidget/StreakWidgetLiveActivity.swift`, `VerseTaskWidget/VerseTaskWidgetLiveActivity.swift`, `LockScreenIconWidget/LockScreenIconWidgetLiveActivity.swift`.

**Apple system frameworks (main app, no SPM):**
- Photos + UIKit — saving share cards in `BIBLE TODO/ShareableCardViews.swift` (`PHPhotoLibrary`, `ImageRenderer`).

**Testing:**
- Swift Testing (`import Testing`) — unit tests in `BIBLE TODOTests/BIBLE_TODOTests.swift`.
- XCTest — UI tests in `BIBLE TODOUITests/BIBLE_TODOUITests.swift` and `BIBLE TODOUITests/BIBLE_TODOUITestsLaunchTests.swift`.

**Build/Dev:**
- Xcode project `BIBLE TODO.xcodeproj` (object version 77), schemes under `BIBLE TODO.xcodeproj/xcshareddata/xcschemes/`.
- Not detected: CocoaPods (`Podfile`), Carthage, standalone `Package.swift` at repo root.

## Key Dependencies

**Critical:**
- `Supabase` (SwiftPM product from [supabase-swift](https://github.com/supabase/supabase-swift)) — requirement `upToNextMajorVersion` minimum 2.0.0 in `BIBLE TODO.xcodeproj/project.pbxproj`; resolved **2.43.1** in `Package.resolved`. Used in `BIBLE TODO/SupabaseConfig.swift`, `BIBLE TODO/BibleTodoRepository.swift`, `BIBLE TODO/AppState.swift`.

**Transitive (pinned in `Package.resolved`):**
- `swift-crypto` 4.3.1, `swift-http-types` 1.5.1, `swift-asn1` 1.6.0 — cryptographic and HTTP types for the Supabase stack.
- `swift-clocks` 1.0.6, `swift-concurrency-extras` 1.3.2, `xctest-dynamic-overlay` 1.9.0 — supporting libraries pulled by the Supabase / Point-Free ecosystem.

**Infrastructure:**
- Not applicable (no server code in this repo).

## Configuration

**Environment / secrets:**
- Build-time values: `Config/AppConfig.xcconfig` defines `SUPABASE_URL` and `SUPABASE_ANON_KEY` and `#include?` optional `Secrets.xcconfig`.
- Template for local secrets: `Config/Secrets.example.xcconfig` (copy to `Secrets.xcconfig`; gitignored per comments there — do not commit real keys).
- Runtime read: `BIBLE TODO/Info.plist` maps `SUPABASE_URL` / `SUPABASE_ANON_KEY` from `$(SUPABASE_URL)` / `$(SUPABASE_ANON_KEY)`; `BIBLE TODO/SupabaseConfig.swift` reads them via `Bundle.main` and builds `SupabaseClient` when both are non-empty.

**Build:**
- Main app Debug/Release use `baseConfigurationReference` → `Config/AppConfig.xcconfig` in `BIBLE TODO.xcodeproj/project.pbxproj`.

**Capabilities / plist:**
- `BIBLE TODO/Info.plist`: `CFBundleDisplayName` “Bible Life”, photo library add usage string, `UIBackgroundModes` includes `remote-notification` (no in-repo Swift registration for push was found).

## Platform Requirements

**Development:**
- macOS with Xcode capable of building iOS targets at the project’s deployment target; Swift 5 toolchain as set in the project.

**Production:**
- iOS application target “BIBLE TODO” with three embedded widget extensions (`StreakWidgetExtension`, `VerseTaskWidgetExtension`, `LockScreenIconWidgetExtension`) per `BIBLE TODO.xcodeproj/project.pbxproj`.

---

*Stack analysis: 2026-04-12*
