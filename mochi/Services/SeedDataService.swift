import Foundation
import SwiftData

@MainActor
enum SeedDataService {
    // Seeds demo data and the store catalog on first launch.
    static func seedIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<AppState>()
        let existingState = (try? context.fetch(descriptor))?.first
        guard existingState == nil else { return }

        let now = Date()
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? startOfToday

        let appState = AppState(
            lastDailyReset: startOfToday,
            lastWeeklyReset: startOfWeek,
            selectedPetSpecies: .cat,
            tutorialSeen: false,
            currentStreak: 0
        )
        context.insert(appState)

        let pet = Pet(
            name: "Mochi",
            species: .cat,
            mood: 85,
            hunger: 80,
            cleanliness: 78,
            level: 1,
            xp: 0,
            coins: 20
        )
        context.insert(pet)

        let demoHabits = [
            Habit(title: "Drink water", scheduleType: .daily),
            Habit(title: "Walk 10 min", scheduleType: .xTimesPerWeek, targetPerWeek: 3),
            Habit(title: "Stretch breaks", scheduleType: .xTimesPerDay, targetPerDay: 2),
            Habit(title: "Read 5 pages", scheduleType: .daily)
        ]
        demoHabits.forEach { context.insert($0) }

        let catalog = [
            InventoryItem(type: .outfit, name: "Bandana", price: 30, owned: false, equipped: false, assetName: "bandana", petSpecies: .dog),
            InventoryItem(type: .outfit, name: "Royal Crown", price: 60, owned: false, equipped: false, assetName: "crown", petSpecies: .cat),
            InventoryItem(type: .outfit, name: "Sparkle Charm", price: 45, owned: false, equipped: false, assetName: "sparkles", petSpecies: .bunny),
            InventoryItem(type: .outfit, name: "Snow Scarf", price: 35, owned: false, equipped: false, assetName: "scarf", petSpecies: .penguin),
            InventoryItem(type: .room, name: "Cozy Home", price: 40, owned: false, equipped: false, assetName: "house"),
            InventoryItem(type: .room, name: "Beach Resort", price: 55, owned: false, equipped: false, assetName: "beach"),
            InventoryItem(type: .room, name: "Dreamy Bed", price: 70, owned: false, equipped: false, assetName: "bed.double"),
            InventoryItem(type: .room, name: "Ice Igloo", price: 65, owned: false, equipped: false, assetName: "igloo")
        ]
        catalog.forEach { context.insert($0) }
    }
}
