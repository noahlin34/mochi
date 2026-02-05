# mochi

CozyPet Habits is a Tamagotchi-style habit tracker where daily actions care for your pet, earn coins, and unlock customization. It’s fully offline-first, built with SwiftUI + SwiftData.

![Platform](https://img.shields.io/badge/platform-iOS-000000?style=for-the-badge&logo=apple)
![Swift](https://img.shields.io/badge/Swift-5.9%2B-F05138?style=for-the-badge&logo=swift)
![SwiftUI](https://img.shields.io/badge/SwiftUI-UI-0A84FF?style=for-the-badge)

## Highlights
- Offline-first habit tracking with a pet-care loop.
- Rewards, coins, and cosmetic shop.
- Multiple pets (dog, penguin, lion) with per-pet outfits.
- Local reminders (user-enabled notifications).
- Polished UI with animations, haptics, and tutorial flow.

## Quick Start
1. Open `mochi.xcodeproj` in Xcode.
2. Select an iOS 18+ simulator.
3. Run the app.

Command line build:
```bash
xcodebuild -scheme mochi -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Features
### Pet Care Loop
- Complete habits to earn coins and XP.
- Energy, hunger, and cleanliness degrade daily.
- Rewards and mood replenishment trigger feedback animations + haptics.

### Habits
- Daily and weekly habits.
- “X times per day” and “X times per week” thresholds.
- Reward logic triggers only when thresholds are met.

### Shop
- Outfits (pet-specific) and rooms (shared across pets).
- Equip to change the pet sprite.
- Optional filter to show items for the active pet.

### Notifications
- Local daily reminder (no backend).
- Enable and set time from Settings.

## Project Structure
```
mochi/
  Models/          SwiftData models and enums
  Services/        Game logic, resets, seed data, notifications
  Utilities/       Theme, haptics, reactions, chroma key
  Views/           Screens and components (Home, Habits, Store, Settings)
  Assets.xcassets/ Images, icons, and room assets
```

## Adding / Replacing Pet Art
Pet art is PNG-based and can be chroma-keyed. Any red (#FF0000) background is automatically removed.

Recommended:
- Transparent PNGs are ideal.
- If using a red background, keep it pure #FF0000 for clean keying.

## Development Notes
- SwiftUI + SwiftData only (no third-party libs).
- Local-only persistence.
- The tutorial runs on first launch and captures the user’s name.

## Troubleshooting
**Notifications not appearing?**
- Ensure notifications are enabled in iOS Settings.
- In-app toggle must be on to schedule reminders.

**Sprites showing red backgrounds?**
- Confirm the background is pure #FF0000 (255, 0, 0).

---
Built to be cozy, simple, and fast to iterate.
