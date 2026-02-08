# Repository Guidelines

## Project Snapshot
- `mochi` is an offline-first iOS habit tracker/pet-care game built with SwiftUI + SwiftData.
- The app currently includes onboarding/tutorial flow, animated splash, local notification reminders, shop/customization, and pet sprite/chroma-key rendering helpers.
- No backend or third-party package dependencies are used.

## Project Structure & Module Organization
- `mochi/mochiApp.swift`: app entry point, SwiftData container setup, and persistent store recovery.
- `mochi/ContentView.swift`: bootstrap flow (seed/reset/reminders), tab shell, splash gating, tutorial presentation.
- `mochi/Models/`: SwiftData models and enums (`Habit`, `Pet`, `InventoryItem`, `AppState`, shared enums).
- `mochi/Services/`: game/domain logic (`GameEngine`, `SeedDataService`, `NotificationManager`).
- `mochi/Views/`: feature screens and UI components (`HomeView`, `HabitsView`, `PetView`, `StoreView`, `SettingsView`, `TutorialView`, `SplashView`, effects, tab bar).
- `mochi/Utilities/`: shared helpers (`AppTheme`, `Haptics`, `PetReactionController`, `SpriteSheet`, `ChromaKey`, layout/preview helpers).
- `mochi/Assets.xcassets/`: app icon, launch assets, pets, outfits, and room art.
- `mochi/LaunchScreen.storyboard`: launch screen configuration.
- `mochi.xcodeproj/`: project and scheme configuration.

## Build, Test, and Development Commands
- `open mochi.xcodeproj`: open in Xcode.
- `xcodebuild -list -project mochi.xcodeproj`: verify schemes/targets on this machine.
- `xcodebuild -scheme mochi -configuration Debug build`: debug build from CLI.
- `xcodebuild -scheme mochi -destination 'platform=iOS Simulator,name=iPhone 16' build`: simulator build (use any installed simulator name).
- `xcodebuild -scheme mochi -destination 'platform=iOS Simulator,name=iPhone 16' test`: run tests once a test target exists.

## Coding Style & Naming Conventions
- Use standard Swift style with 4-space indentation and Xcode default formatting.
- Follow Swift naming conventions: `UpperCamelCase` for types and `lowerCamelCase` for functions/properties.
- Keep view code focused; extract subviews/services when screen logic grows.
- Keep game/business rules in `Services/` and data definitions in `Models/`; avoid embedding rule logic directly in views.
- No formatter/linter is configured; avoid trailing whitespace and broad unrelated formatting changes.

## Testing Guidelines
- There is currently no committed XCTest target.
- For new logic-heavy changes (especially `Services/` and `Models/`), add XCTest coverage in a new test target (for example `mochiTests`).
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
- Do not commit secrets or API keys; this app should remain local-only.
- Avoid adding personal Xcode artifacts in `mochi.xcodeproj/xcuserdata`.
- Keep large generated media limited to `mochi/Assets.xcassets` and remove unused assets to keep repository size manageable.
