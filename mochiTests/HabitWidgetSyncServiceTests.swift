import SwiftData
import XCTest
@testable import mochi

final class HabitWidgetSyncServiceTests: XCTestCase {
    @MainActor
    func testSyncBuildsSnapshotAndReloadsBothWidgetKinds() throws {
        let context = try SwiftDataTestSupport.makeInMemoryContext()
        let appState = AppState(
            lastDailyReset: SwiftDataTestSupport.date("2026-02-10T00:00:00Z"),
            lastWeeklyReset: SwiftDataTestSupport.date("2026-02-09T00:00:00Z")
        )
        context.insert(appState)

        let olderHabit = Habit(
            title: "Read",
            scheduleType: .xTimesPerDay,
            targetPerDay: 3,
            completedCountToday: 2,
            completedThisWeek: 6,
            createdAt: SwiftDataTestSupport.date("2026-02-01T09:00:00Z")
        )
        let newerHabit = Habit(
            title: "Walk",
            scheduleType: .weekly,
            completedCountToday: 1,
            completedThisWeek: 1,
            createdAt: SwiftDataTestSupport.date("2026-02-03T09:00:00Z")
        )
        context.insert(newerHabit)
        context.insert(olderHabit)

        let store = SnapshotStoreSpy()
        let reloader = WidgetReloaderSpy()
        let now = SwiftDataTestSupport.date("2026-02-10T12:00:00Z")

        HabitWidgetSyncService.sync(
            context: context,
            now: { now },
            store: store,
            reloader: reloader
        )

        XCTAssertEqual(store.savedSnapshots.count, 1)
        let snapshot = try XCTUnwrap(store.savedSnapshots.first)
        XCTAssertEqual(snapshot.generatedAt, now)
        XCTAssertEqual(snapshot.lastDailyReset, appState.lastDailyReset)
        XCTAssertEqual(snapshot.lastWeeklyReset, appState.lastWeeklyReset)
        XCTAssertEqual(snapshot.habits.count, 2)

        XCTAssertEqual(snapshot.habits[0].title, "Read")
        XCTAssertEqual(snapshot.habits[0].schedule, .xTimesPerDay)
        XCTAssertEqual(snapshot.habits[0].targetPerDay, 3)
        XCTAssertEqual(snapshot.habits[0].completedCountToday, 2)

        XCTAssertEqual(snapshot.habits[1].title, "Walk")
        XCTAssertEqual(snapshot.habits[1].schedule, .weekly)
        XCTAssertEqual(snapshot.habits[1].completedThisWeek, 1)

        XCTAssertEqual(reloader.reloadedKinds.count, 2)
        XCTAssertTrue(reloader.reloadedKinds.contains(HabitWidgetSyncService.lockScreenWidgetKind))
        XCTAssertTrue(reloader.reloadedKinds.contains(HabitWidgetSyncService.homeScreenWidgetKind))
    }

    @MainActor
    func testSyncDoesNothingWhenAppStateIsMissing() throws {
        let context = try SwiftDataTestSupport.makeInMemoryContext()
        let store = SnapshotStoreSpy()
        let reloader = WidgetReloaderSpy()

        HabitWidgetSyncService.sync(
            context: context,
            now: Date.init,
            store: store,
            reloader: reloader
        )

        XCTAssertTrue(store.savedSnapshots.isEmpty)
        XCTAssertTrue(reloader.reloadedKinds.isEmpty)
    }
}

private final class SnapshotStoreSpy: HabitWidgetSnapshotStoring {
    private(set) var savedSnapshots: [HabitWidgetSnapshot] = []

    func save(_ snapshot: HabitWidgetSnapshot) {
        savedSnapshots.append(snapshot)
    }
}

private final class WidgetReloaderSpy: WidgetTimelineReloading {
    private(set) var reloadedKinds: [String] = []

    func reloadTimelines(ofKind kind: String) {
        reloadedKinds.append(kind)
    }
}
