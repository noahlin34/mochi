import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    @Query(sort: \Pet.createdAt) private var pets: [Pet]
    @Query(sort: \AppState.createdAt) private var appStates: [AppState]
    @Query(sort: \Habit.createdAt) private var habits: [Habit]

    @StateObject private var reactionController = PetReactionController()
    @State private var selection: AppTab = .home

    private let engine = GameEngine()

    var body: some View {
        Group {
            if let pet = pets.first, let appState = appStates.first {
                TabView(selection: $selection) {
                    HomeView(pet: pet, appState: appState)
                        .tag(AppTab.home)

                    HabitsView(pet: pet, appState: appState)
                        .tag(AppTab.habits)

                    StoreView(pet: pet)
                        .tag(AppTab.store)

                    SettingsView(pet: pet, appState: appState)
                        .tag(AppTab.settings)
                }
                .toolbar(.hidden, for: .tabBar)
                .background(Color.appBackground.ignoresSafeArea())
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    AppTabBar(selection: $selection)
                        .padding(.top, 6)
                        .padding(.bottom, 10)
                        .frame(maxWidth: .infinity)
                        .background(Color.appBackground)
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
