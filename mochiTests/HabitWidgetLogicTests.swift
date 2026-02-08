import XCTest
@testable import mochi

final class HabitWidgetLogicTests: XCTestCase {
    private var calendar: Calendar!

    override func setUp() {
        super.setUp()
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        calendar = utc
    }

    func testEmptySnapshotYieldsZeroProgress() {
        let snapshot = HabitWidgetSnapshot(
            generatedAt: date("2026-02-08T10:00:00Z"),
            lastDailyReset: date("2026-02-08T00:00:00Z"),
            lastWeeklyReset: date("2026-02-02T00:00:00Z"),
            habits: []
        )

        let result = HabitWidgetProgressCalculator.computeDisplayProgress(
            snapshot: snapshot,
            now: date("2026-02-06T10:00:00Z"),
            calendar: calendar
        )

        XCTAssertEqual(result.done, 0)
        XCTAssertEqual(result.total, 0)
        XCTAssertEqual(result.remaining, 0)
    }

    func testMixedSchedulesComputesDoneAndRemaining() {
        let habits: [HabitWidgetHabitRecord] = [
            .init(id: UUID(), schedule: .daily, targetPerDay: nil, targetPerWeek: nil, completedCountToday: 1, completedThisWeek: 1),
            .init(id: UUID(), schedule: .weekly, targetPerDay: nil, targetPerWeek: nil, completedCountToday: 0, completedThisWeek: 0),
            .init(id: UUID(), schedule: .xTimesPerDay, targetPerDay: 3, targetPerWeek: nil, completedCountToday: 3, completedThisWeek: 3),
            .init(id: UUID(), schedule: .xTimesPerWeek, targetPerDay: nil, targetPerWeek: 2, completedCountToday: 1, completedThisWeek: 1)
        ]

        let snapshot = HabitWidgetSnapshot(
            generatedAt: date("2026-02-08T10:00:00Z"),
            lastDailyReset: date("2026-02-08T00:00:00Z"),
            lastWeeklyReset: date("2026-02-02T00:00:00Z"),
            habits: habits
        )

        let result = HabitWidgetProgressCalculator.computeDisplayProgress(
            snapshot: snapshot,
            now: date("2026-02-06T10:00:00Z"),
            calendar: calendar
        )

        XCTAssertEqual(result.total, 4)
        XCTAssertEqual(result.done, 2)
        XCTAssertEqual(result.remaining, 2)
    }

    func testDailyProjectionResetsDailyCounters() {
        let snapshot = HabitWidgetSnapshot(
            generatedAt: date("2026-02-08T22:00:00Z"),
            lastDailyReset: date("2026-02-08T00:00:00Z"),
            lastWeeklyReset: date("2026-02-02T00:00:00Z"),
            habits: [
                .init(id: UUID(), schedule: .daily, targetPerDay: nil, targetPerWeek: nil, completedCountToday: 1, completedThisWeek: 1),
                .init(id: UUID(), schedule: .xTimesPerDay, targetPerDay: 2, targetPerWeek: nil, completedCountToday: 2, completedThisWeek: 2)
            ]
        )

        let result = HabitWidgetProgressCalculator.computeDisplayProgress(
            snapshot: snapshot,
            now: date("2026-02-09T00:30:00Z"),
            calendar: calendar
        )

        XCTAssertEqual(result.done, 0)
        XCTAssertEqual(result.total, 2)
        XCTAssertEqual(result.remaining, 2)
    }

    func testWeeklyProjectionResetsWeeklyCounters() {
        let snapshot = HabitWidgetSnapshot(
            generatedAt: date("2026-02-08T22:00:00Z"),
            lastDailyReset: date("2026-02-08T00:00:00Z"),
            lastWeeklyReset: date("2026-02-02T00:00:00Z"),
            habits: [
                .init(id: UUID(), schedule: .weekly, targetPerDay: nil, targetPerWeek: nil, completedCountToday: 0, completedThisWeek: 1),
                .init(id: UUID(), schedule: .xTimesPerWeek, targetPerDay: nil, targetPerWeek: 3, completedCountToday: 0, completedThisWeek: 3)
            ]
        )

        let result = HabitWidgetProgressCalculator.computeDisplayProgress(
            snapshot: snapshot,
            now: date("2026-02-10T10:00:00Z"),
            calendar: calendar
        )

        XCTAssertEqual(result.done, 0)
        XCTAssertEqual(result.total, 2)
        XCTAssertEqual(result.remaining, 2)
    }

    func testXTimesTargetsClampToOne() {
        let snapshot = HabitWidgetSnapshot(
            generatedAt: date("2026-02-08T10:00:00Z"),
            lastDailyReset: date("2026-02-06T00:00:00Z"),
            lastWeeklyReset: date("2026-02-06T00:00:00Z"),
            habits: [
                .init(id: UUID(), schedule: .xTimesPerDay, targetPerDay: 0, targetPerWeek: nil, completedCountToday: 1, completedThisWeek: 1),
                .init(id: UUID(), schedule: .xTimesPerWeek, targetPerDay: nil, targetPerWeek: 0, completedCountToday: 0, completedThisWeek: 1)
            ]
        )

        let result = HabitWidgetProgressCalculator.computeDisplayProgress(
            snapshot: snapshot,
            now: date("2026-02-06T10:00:00Z"),
            calendar: calendar
        )

        XCTAssertEqual(result.done, 2)
        XCTAssertEqual(result.total, 2)
        XCTAssertEqual(result.remaining, 0)
    }

    func testSnapshotStoreRoundTripAndCorruptDataHandling() {
        let suiteName = "mochi.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)

        let snapshot = HabitWidgetSnapshot(
            generatedAt: date("2026-02-08T10:00:00Z"),
            lastDailyReset: date("2026-02-08T00:00:00Z"),
            lastWeeklyReset: date("2026-02-02T00:00:00Z"),
            habits: [
                .init(id: UUID(), schedule: .daily, targetPerDay: nil, targetPerWeek: nil, completedCountToday: 1, completedThisWeek: 1)
            ]
        )

        HabitWidgetSnapshotStore.save(snapshot, defaults: defaults)
        let loaded = HabitWidgetSnapshotStore.load(defaults: defaults)
        XCTAssertEqual(loaded, snapshot)

        defaults?.set(Data("invalid".utf8), forKey: HabitWidgetSnapshotStore.snapshotKey)
        XCTAssertNil(HabitWidgetSnapshotStore.load(defaults: defaults))

        defaults?.removePersistentDomain(forName: suiteName)
    }

    private func date(_ iso8601: String) -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: iso8601) ?? Date(timeIntervalSince1970: 0)
    }
}
