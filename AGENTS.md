# Repository Guidelines

## Project Snapshot
- `mochi` is an offline-first iOS habit tracker/pet-care game built with SwiftUI + SwiftData.
- The app currently includes onboarding/tutorial flow, animated splash, local notification reminders, shop/customization, widget support, and pet sprite/chroma-key rendering helpers.
- Subscription/paywall flows are integrated with RevenueCat (`RevenueCat` + `RevenueCatUI`) via Swift Package Manager.
- Persistence is local-only (SwiftData + app group defaults for widgets); there is no backend.

## Project Structure & Module Organization
- `mochi/mochiApp.swift`: app entry point, SwiftData container setup/recovery, and RevenueCat bootstrap.
- `mochi/ContentView.swift`: bootstrap flow (seed/reset/reminders/widget sync), tab shell, splash gating, tutorial presentation.
- `mochi/Models/`: SwiftData models and enums (`Habit`, `Pet`, `InventoryItem`, `AppState`, shared enums).
- `mochi/Services/`: game/domain logic (`GameEngine`, `SeedDataService`, `NotificationManager`) plus subscription and widget sync/storage/calculators (`RevenueCatManager`, `HabitWidgetSyncService`, `HabitWidgetSnapshotStore`, `HabitWidgetProgressCalculator`, `HabitWidgetListCalculator`).
- `mochi/Shared/`: cross-target shared types used by app, widgets, and tests (`HabitWidgetSnapshot`).
- `mochi/Views/`: feature screens and UI components (`HomeView`, `HabitsView`, `PetView`, `StoreView`, `SettingsView`, `TutorialView`, `SplashView`, form/effects/tab bar components).
- `mochi/Utilities/`: shared helpers (`AppTheme`, `Haptics`, `PetReactionController`, `SpriteSheet`, `ChromaKey`, layout/preview helpers, shapes).
- `mochi/Assets.xcassets/`: app icon, launch assets, pets, outfits, and room art.
- `mochi/LaunchScreen.storyboard`: launch screen configuration.
- `mochiWidgets/`: WidgetKit extension target (`MochiWidgetsExtension`) with lock-screen and home-screen widgets.
- `mochiTests/`: XCTest target (`mochiTests`) for widget logic and reaction controller behavior.
- `mochi.xcodeproj/`: project, targets, schemes, and SwiftPM configuration.

## Build, Test, and Development Commands
- `open mochi.xcodeproj`: open in Xcode.
- `xcodebuild -list -project mochi.xcodeproj`: verify schemes/targets on this machine.
- `xcodebuild -scheme mochi -showdestinations -project mochi.xcodeproj`: list available simulators/devices before running build/test commands.
- `xcodebuild -scheme mochi -configuration Debug build`: debug build from CLI.
- `xcodebuild -scheme mochi -destination 'platform=iOS Simulator,name=iPhone 16' build`: simulator build (use any installed simulator name).
- `xcodebuild -scheme mochi -destination 'platform=iOS Simulator,name=iPhone 16' test`: run app unit tests.
- `xcodebuild -scheme MochiWidgetsExtension -destination 'platform=iOS Simulator,name=iPhone 16' build`: build the widget extension target.

## Coding Style & Naming Conventions
- Use standard Swift style with 4-space indentation and Xcode default formatting.
- Follow Swift naming conventions: `UpperCamelCase` for types and `lowerCamelCase` for functions/properties.
- Keep view code focused; extract subviews/services when screen logic grows.
- Keep game/business rules in `Services/` and data definitions in `Models/`; avoid embedding rule logic directly in views.
- Keep widget data contracts in `mochi/Shared/` and shared widget logic in `mochi/Services/` so app, widget extension, and tests stay in sync.
- No formatter/linter is configured; avoid trailing whitespace and broad unrelated formatting changes.

## Testing Guidelines
- A committed XCTest target exists at `mochiTests/`.
- Current tests cover widget progress/list/snapshot logic and `PetReactionController` behavior.
- For new logic-heavy changes (especially `Services/`, `Models/`, and widget calculations), add or extend XCTest coverage in `mochiTests`.
- Keep tests deterministic (fixed dates/inputs for streak, reset, and reward logic).
- Before submitting, run `xcodebuild -scheme mochi -destination 'platform=iOS Simulator,name=iPhone 16' build` and any available tests.

## Commit & Pull Request Guidelines
- Use concise imperative commit messages (for example: `Add daily reminder toggle persistence`).
- Keep commits scoped to one logical change.
- PRs should include:
  - brief summary of behavior changes,
  - testing notes (simulator/device + commands run),
  - screenshots/video for UI or animation changes.

## Security & Configuration Tips
- Do not commit secrets or production API keys; RevenueCat configuration should use safe environment-appropriate keys.
- Avoid adding personal Xcode artifacts in `mochi.xcodeproj/xcuserdata`.
- Keep the app group identifier (`group.com.noahlin.mochi`) aligned across entitlements and widget snapshot storage.
- Keep large generated media limited to `mochi/Assets.xcassets` and remove unused assets to keep repository size manageable.
