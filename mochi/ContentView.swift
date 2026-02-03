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
    @State private var tabBarHeight: CGFloat = 0

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
                        .padding(.top, 0)
                        .padding(.bottom, 4)
                        .frame(maxWidth: .infinity)
                        .trackTabBarHeight { height in
                            tabBarHeight = height
                        }
                }
                .fullScreenCover(
                    isPresented: Binding(
                        get: { !appState.tutorialSeen },
                        set: { newValue in
                            if !newValue {
                                appState.tutorialSeen = true
                            }
                        }
                    )
                ) {
                    TutorialView(pet: pet, appState: appState)
                        .interactiveDismissDisabled()
                }
            } else {
                ProgressView("Preparing mochi...")
            }
        }
        .environmentObject(reactionController)
        .environment(\.tabBarHeight, tabBarHeight)
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
    let preview = PreviewData.make()
    return ContentView()
        .modelContainer(preview.container)
        .environmentObject(PetReactionController())
}
