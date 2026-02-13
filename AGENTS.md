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

## Pet Item Rendering (Sprite Swap + Chroma Key Overlay)
- Outfit rendering has two distinct modes and both are actively used:
  - `replaceSprite`: the equipped item changes the pet image/sprite asset itself.
  - `overlay`: the equipped item is drawn on top of the base pet using chroma key.
- The mode is controlled by `InventoryItem.equipStyle` (`InventoryEquipStyle`) in `mochi/Models/InventoryItem.swift` and `mochi/Models/Enums.swift`.
- `replaceSprite` items follow existing species/pet asset fallback logic in `mochi/Views/PetView.swift` (for example, `dog_pet_<asset>`, `penguin_pet_<asset>`, sprite sheets).
- `overlay` items are rendered by overlay item views in `mochi/Views/PetView.swift` and processed through `ChromaKeyedImage` from `mochi/Utilities/ChromaKey.swift`.
- Overlay source art is expected to use green-screen background (`#00FF00`), which is removed by chroma key settings (threshold/smoothing) in `PetView`.
- Overlay behavior is intentionally more complex than simple outfit swap:
  - one base outfit (`replaceSprite`) can be active while multiple overlay items are also active,
  - `HomeView` and `StoreView` pass these separately (`baseOutfitSymbol` vs `overlaySymbols`),
  - store equip logic only enforces exclusivity among `replaceSprite` outfits.
- Overlay asset name resolution supports multiple conventions in `PetView`/`StoreView` (species-specific and shared fallbacks), including:
  - `<species>_pet_overlay_<asset>`
  - `<species>_overlay_<asset>`
  - `pet_overlay_<asset>`
  - `overlay_<asset>`
  - `<asset>`
- Item-specific overlay placement and chroma tuning are per-item code paths in `PetView`:
  - placement via `resolvedPlacement(...)` and per-item placement helpers,
  - chroma aggressiveness via `resolvedChromaSettings(...)`.
- When adding new overlay catalog items, set `equipStyle: .overlay` in `SeedDataService` seeds so existing users receive them through catalog upsert.

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
