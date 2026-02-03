# Repository Guidelines

## Project Structure & Module Organization
- `mochi/` contains the app source code.
- `mochi/mochiApp.swift` is the application entry point and configures the SwiftData `ModelContainer`.
- `mochi/ContentView.swift` composes the root experience and tabs.
- `mochi/Views/` contains SwiftUI screens and reusable view components (home, habits, pet, store, settings, forms, tab bar).
- `mochi/Models/` contains SwiftData models and app state (`Habit`, `Pet`, `InventoryItem`, `AppState`, enums).
- `mochi/Services/` contains game logic and seed data helpers (`GameEngine`, `SeedDataService`).
- `mochi/Utilities/` contains app-wide helpers (theme, shapes, haptics, reaction controller).
- `mochi/Assets.xcassets/` holds app icons and color assets.
- `mochi.xcodeproj/` is the Xcode project configuration.

## Build, Test, and Development Commands
- `open mochi.xcodeproj` opens the project in Xcode for local development.
- `xcodebuild -scheme mochi -configuration Debug build` builds the app from the command line.
- `xcodebuild -scheme mochi -destination 'platform=iOS Simulator,name=iPhone 15' build` builds for a specific simulator (adjust the device name to one installed locally).
- `xcodebuild -scheme mochi test` runs tests, if test targets are added.

## Coding Style & Naming Conventions
- Use standard Swift style with 4-space indentation and SwiftUI formatting.
- Prefer descriptive, Swift API-style naming: `UpperCamelCase` for types, `lowerCamelCase` for variables and functions.
- Keep SwiftUI views small and focused; extract subviews when a view grows beyond a single screen of logic.
- No formatter or linter is configured; follow Xcode’s default formatting and avoid trailing whitespace.

## Testing Guidelines
- There are no test targets in the repository yet.
- When adding tests, use XCTest and name files `*Tests.swift` in a new test target (e.g., `mochiTests`).
- Keep tests deterministic and run them with `xcodebuild -scheme mochi test` before submitting changes.

## Commit & Pull Request Guidelines
- Git history currently contains only `Initial Commit`, so no strict convention is established.
- Use concise, imperative commit messages (e.g., “Add item deletion animation”).
- PRs should include a brief summary, testing notes, and screenshots for UI changes.

## Security & Configuration Tips
- Avoid committing personal Xcode user data under `mochi.xcodeproj/xcuserdata`.
- Store any future secrets outside the repo (e.g., in local environment settings or Xcode build settings).
