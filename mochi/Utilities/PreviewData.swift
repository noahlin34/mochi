import SwiftUI
import SwiftData

@MainActor
struct PreviewDataSet {
    let container: ModelContainer
    let pet: Pet
    let appState: AppState
}

@MainActor
enum PreviewData {
    static func make() -> PreviewDataSet {
        let schema = Schema([Habit.self, Pet.self, InventoryItem.self, AppState.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        let context = container.mainContext

        let now = Date()
        let appState = AppState(
            lastDailyReset: now,
            lastWeeklyReset: now,
            selectedPetSpecies: .dog,
            tutorialSeen: true,
            currentStreak: 4
        )
        context.insert(appState)

        let pet = Pet(
            name: "Mochi",
            species: .dog,
            mood: 86,
            hunger: 78,
            cleanliness: 84,
            level: 2,
            xp: 140,
            coins: 247
        )
        context.insert(pet)

        let habits = [
            Habit(title: "Drink water", scheduleType: .daily, completedCountToday: 1, completedThisWeek: 4),
            Habit(title: "Walk 10 min", scheduleType: .xTimesPerWeek, targetPerWeek: 3, completedCountToday: 0, completedThisWeek: 2),
            Habit(title: "Stretch breaks", scheduleType: .xTimesPerDay, targetPerDay: 2, completedCountToday: 1, completedThisWeek: 6),
            Habit(title: "Read 5 pages", scheduleType: .daily, completedCountToday: 0, completedThisWeek: 3)
        ]
        habits.forEach { context.insert($0) }

        let catalog = [
            InventoryItem(type: .outfit, name: "Bandana", price: 30, owned: true, equipped: true, assetName: "bandana", petSpecies: .dog),
            InventoryItem(type: .outfit, name: "Royal Crown", price: 60, owned: false, equipped: false, assetName: "crown", petSpecies: .cat),
            InventoryItem(type: .outfit, name: "Sparkle Charm", price: 45, owned: false, equipped: false, assetName: "sparkles", petSpecies: .bunny),
            InventoryItem(type: .outfit, name: "Snow Scarf", price: 35, owned: false, equipped: false, assetName: "scarf", petSpecies: .penguin),
            InventoryItem(type: .room, name: "Cozy Home", price: 40, owned: true, equipped: true, assetName: "house"),
            InventoryItem(type: .room, name: "Beach Resort", price: 55, owned: false, equipped: false, assetName: "beach"),
            InventoryItem(type: .room, name: "Dreamy Bed", price: 70, owned: false, equipped: false, assetName: "bed.double"),
            InventoryItem(type: .room, name: "Ice Igloo", price: 65, owned: false, equipped: false, assetName: "igloo")
        ]
        catalog.forEach { context.insert($0) }

        return PreviewDataSet(container: container, pet: pet, appState: appState)
    }
}
