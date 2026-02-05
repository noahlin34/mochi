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

    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @AppStorage("reminderHour") private var reminderHour: Int = 9
    @AppStorage("reminderMinute") private var reminderMinute: Int = 0

    private let engine = GameEngine()

    var body: some View {
        Group {
            if let pet = pets.first, let appState = appStates.first {
                ZStack {
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

                    VStack {
                        HStack {
                            statBurstStack
                            Spacer()
                            coinBurstView
                        }
                        Spacer()
                    }
                    .padding(.top, 12)
                    .padding(.horizontal, 24)
                    .allowsHitTesting(false)
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
        .onChange(of: reactionController.coinBurst) { _, newValue in
            if newValue != nil {
                Haptics.success()
            }
        }
        .onChange(of: reactionController.statBursts.count) { oldValue, newValue in
            if newValue > oldValue {
                Haptics.light()
            }
        }
        .task {
            SeedDataService.seedIfNeeded(context: modelContext)
            engine.runResetsIfNeeded(context: modelContext)
            Task {
                await NotificationManager.updateDailyReminder(
                    enabled: notificationsEnabled,
                    hour: reminderHour,
                    minute: reminderMinute
                )
            }
        }
        .onChange(of: scenePhase) { phase in
            guard phase == .active else { return }
            engine.runResetsIfNeeded(context: modelContext)
            Task {
                await NotificationManager.updateDailyReminder(
                    enabled: notificationsEnabled,
                    hour: reminderHour,
                    minute: reminderMinute
                )
            }
        }
    }

    @ViewBuilder
    private var coinBurstView: some View {
        if let burst = reactionController.coinBurst {
            CoinBurstView(amount: burst.amount) {
                reactionController.clearCoinBurst()
            }
            .transition(.opacity)
            .zIndex(10)
        }
    }

    private var statBurstStack: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(reactionController.statBursts) { burst in
                StatBurstView(burst: burst)
                    .transition(.opacity)
            }
        }
    }
}

#Preview {
    let preview = PreviewData.make()
    return ContentView()
        .modelContainer(preview.container)
        .environmentObject(PetReactionController())
}
