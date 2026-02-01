import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    @Query(sort: \Pet.createdAt) private var pets: [Pet]
    @Query(sort: \AppState.createdAt) private var appStates: [AppState]
    @Query(sort: \Habit.createdAt) private var habits: [Habit]

    @StateObject private var reactionController = PetReactionController()

    private let engine = GameEngine()

    var body: some View {
        Group {
            if let pet = pets.first, let appState = appStates.first {
                TabView {
                    HomeView(pet: pet, appState: appState)
                        .tabItem {
                            Label("Home", systemImage: "house")
                        }

                    HabitsView(pet: pet, appState: appState)
                        .tabItem {
                            Label("Habits", systemImage: "checklist")
                        }

                    StoreView(pet: pet)
                        .tabItem {
                            Label("Store", systemImage: "cart")
                        }

                    SettingsView(pet: pet, appState: appState)
                        .tabItem {
                            Label("Settings", systemImage: "gearshape")
                        }
                }
            } else {
                ProgressView("Preparing mochi...")
            }
        }
        .environmentObject(reactionController)
        .task {
            SeedDataService.seedIfNeeded(context: modelContext)
            engine.runResetsIfNeeded(context: modelContext)
        }
        .onChange(of: scenePhase) { phase in
            guard phase == .active else { return }
            engine.runResetsIfNeeded(context: modelContext)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Habit.self, Pet.self, InventoryItem.self, AppState.self], inMemory: true)
}
