import SwiftUI
import SwiftData
import UIKit

@main
struct MochiApp: App {
    init() {
        // Ensure the system tab bar never shows behind the custom one.
        UITabBar.appearance().isHidden = true
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Habit.self,
            Pet.self,
            InventoryItem.self,
            AppState.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
        }
        .modelContainer(sharedModelContainer)
    }
}
