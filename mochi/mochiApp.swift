import SwiftUI
import SwiftData
import UIKit

@main
struct MochiApp: App {
    @StateObject private var revenueCat = RevenueCatManager()

    init() {
        // Ensure the system tab bar never shows behind the custom one.
        UITabBar.appearance().isHidden = true
        if !AppRuntime.isRunningTests {
            RevenueCatManager.configureSDKIfNeeded()
        }
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Habit.self,
            Pet.self,
            InventoryItem.self,
            AppState.self
        ])
        return Self.makeModelContainer(schema: schema)
    }()

    private static func makeModelContainer(schema: Schema) -> ModelContainer {
        let storeURL = Self.storeURL()
        let configuration = ModelConfiguration(schema: schema, url: storeURL)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            Self.resetStore(at: storeURL)
            do {
                return try ModelContainer(for: schema, configurations: [configuration])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }

    private static func storeURL() -> URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appURL = baseURL.appendingPathComponent("mochi", isDirectory: true)
        try? FileManager.default.createDirectory(at: appURL, withIntermediateDirectories: true)
        return appURL.appendingPathComponent("mochi.store")
    }

    private static func resetStore(at url: URL) {
        let fm = FileManager.default
        let walURL = URL(fileURLWithPath: url.path + "-wal")
        let shmURL = URL(fileURLWithPath: url.path + "-shm")
        let sqliteURLs = [url, walURL, shmURL]
        sqliteURLs.forEach { try? fm.removeItem(at: $0) }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(revenueCat)
                .task {
                    if !AppRuntime.isRunningTests {
                        revenueCat.start()
                    }
                }
                .preferredColorScheme(.light)
        }
        .modelContainer(sharedModelContainer)
    }
}
