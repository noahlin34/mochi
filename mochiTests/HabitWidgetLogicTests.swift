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
            generatedAt: date("2026-02-04T10:00:00Z"),
            lastDailyReset: date("2026-02-04T00:00:00Z"),
            lastWeeklyReset: date("2026-02-04T00:00:00Z"),
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

    func testPreviewRowsEmptySnapshot() {
        let snapshot = HabitWidgetSnapshot(
            generatedAt: date("2026-02-08T10:00:00Z"),
            lastDailyReset: date("2026-02-08T00:00:00Z"),
            lastWeeklyReset: date("2026-02-02T00:00:00Z"),
            habits: []
        )

        let doneTotal = HabitWidgetListCalculator.computeDoneTotal(
            snapshot: snapshot,
            now: date("2026-02-04T10:00:00Z"),
            calendar: calendar
        )
        let rows = HabitWidgetListCalculator.computePreviewRows(
            snapshot: snapshot,
            now: date("2026-02-04T10:00:00Z"),
            calendar: calendar,
            limit: 4
        )

        XCTAssertEqual(doneTotal.done, 0)
        XCTAssertEqual(doneTotal.total, 0)
        XCTAssertEqual(rows, [])
    }

    func testPreviewRowsMixedSchedulesSortingAndStatus() {
        let alphaID = UUID()
        let betaID = UUID()
        let gammaID = UUID()

        let snapshot = HabitWidgetSnapshot(
            generatedAt: date("2026-02-04T10:00:00Z"),
            lastDailyReset: date("2026-02-04T00:00:00Z"),
            lastWeeklyReset: date("2026-02-04T00:00:00Z"),
            habits: [
                .init(
                    id: alphaID,
                    title: "Alpha",
                    createdAt: date("2026-01-01T10:00:00Z"),
                    schedule: .daily,
                    targetPerDay: nil,
                    targetPerWeek: nil,
                    completedCountToday: 1,
                    completedThisWeek: 3
                ),
                .init(
                    id: betaID,
                    title: "Beta",
                    createdAt: date("2026-01-01T09:00:00Z"),
                    schedule: .xTimesPerDay,
                    targetPerDay: 3,
                    targetPerWeek: nil,
                    completedCountToday: 1,
                    completedThisWeek: 2
                ),
                .init(
                    id: gammaID,
                    title: "Gamma",
                    createdAt: date("2026-01-01T11:00:00Z"),
                    schedule: .xTimesPerWeek,
                    targetPerDay: nil,
                    targetPerWeek: 2,
                    completedCountToday: 0,
                    completedThisWeek: 2
                )
            ]
        )

        let doneTotal = HabitWidgetListCalculator.computeDoneTotal(
            snapshot: snapshot,
            now: date("2026-02-04T10:00:00Z"),
            calendar: calendar
        )
        let rows = HabitWidgetListCalculator.computePreviewRows(
            snapshot: snapshot,
            now: date("2026-02-04T10:00:00Z"),
            calendar: calendar,
            limit: 4
        )

        XCTAssertEqual(doneTotal.done, 2)
        XCTAssertEqual(doneTotal.total, 3)
        XCTAssertEqual(rows.count, 3)
        XCTAssertEqual(rows.map(\.title), ["Beta", "Alpha", "Gamma"])
        XCTAssertEqual(rows.first?.progress, 1)
        XCTAssertEqual(rows.first?.target, 3)
        XCTAssertEqual(rows.first?.isDone, false)
    }

    func testPreviewRowsDailyProjectionResetsDailyCounters() {
        let snapshot = HabitWidgetSnapshot(
            generatedAt: date("2026-02-08T23:00:00Z"),
            lastDailyReset: date("2026-02-08T00:00:00Z"),
            lastWeeklyReset: date("2026-02-02T00:00:00Z"),
            habits: [
                .init(
                    id: UUID(),
                    title: "Daily Habit",
                    createdAt: date("2026-01-01T10:00:00Z"),
                    schedule: .daily,
                    targetPerDay: nil,
                    targetPerWeek: nil,
                    completedCountToday: 1,
                    completedThisWeek: 1
                )
            ]
        )

        let rows = HabitWidgetListCalculator.computePreviewRows(
            snapshot: snapshot,
            now: date("2026-02-09T01:00:00Z"),
            calendar: calendar,
            limit: 4
        )

        XCTAssertEqual(rows.first?.progress, 0)
        XCTAssertEqual(rows.first?.target, 1)
        XCTAssertEqual(rows.first?.isDone, false)
    }

    func testPreviewRowsWeeklyProjectionResetsWeeklyCounters() {
        let snapshot = HabitWidgetSnapshot(
            generatedAt: date("2026-02-08T23:00:00Z"),
            lastDailyReset: date("2026-02-08T00:00:00Z"),
            lastWeeklyReset: date("2026-02-02T00:00:00Z"),
            habits: [
                .init(
                    id: UUID(),
                    title: "Weekly Habit",
                    createdAt: date("2026-01-01T10:00:00Z"),
                    schedule: .weekly,
                    targetPerDay: nil,
                    targetPerWeek: nil,
                    completedCountToday: 0,
                    completedThisWeek: 1
                )
            ]
        )

        let rows = HabitWidgetListCalculator.computePreviewRows(
            snapshot: snapshot,
            now: date("2026-02-10T10:00:00Z"),
            calendar: calendar,
            limit: 4
        )

        XCTAssertEqual(rows.first?.progress, 0)
        XCTAssertEqual(rows.first?.target, 1)
        XCTAssertEqual(rows.first?.isDone, false)
    }

    func testPreviewRowsLimitAndTitleFallback() {
        let habits: [HabitWidgetHabitRecord] = [
            .init(id: UUID(), title: "   ", createdAt: date("2026-01-01T00:00:00Z"), schedule: .daily, targetPerDay: nil, targetPerWeek: nil, completedCountToday: 0, completedThisWeek: 0),
            .init(id: UUID(), title: "B", createdAt: date("2026-01-02T00:00:00Z"), schedule: .daily, targetPerDay: nil, targetPerWeek: nil, completedCountToday: 0, completedThisWeek: 0),
            .init(id: UUID(), title: "C", createdAt: date("2026-01-03T00:00:00Z"), schedule: .daily, targetPerDay: nil, targetPerWeek: nil, completedCountToday: 0, completedThisWeek: 0),
            .init(id: UUID(), title: "D", createdAt: date("2026-01-04T00:00:00Z"), schedule: .daily, targetPerDay: nil, targetPerWeek: nil, completedCountToday: 0, completedThisWeek: 0),
            .init(id: UUID(), title: nil, createdAt: date("2026-01-05T00:00:00Z"), schedule: .daily, targetPerDay: nil, targetPerWeek: nil, completedCountToday: 0, completedThisWeek: 0)
        ]
        let snapshot = HabitWidgetSnapshot(
            generatedAt: date("2026-02-08T10:00:00Z"),
            lastDailyReset: date("2026-02-08T00:00:00Z"),
            lastWeeklyReset: date("2026-02-02T00:00:00Z"),
            habits: habits
        )

        let rows = HabitWidgetListCalculator.computePreviewRows(
            snapshot: snapshot,
            now: date("2026-02-08T10:00:00Z"),
            calendar: calendar,
            limit: 4
        )

        XCTAssertEqual(rows.count, 4)
        XCTAssertEqual(rows.first?.title, "Untitled Habit")
    }

    @MainActor
    func testSnapshotDecodesWhenOptionalFieldsMissing() throws {
        let legacySnapshot = LegacyHabitWidgetSnapshot(
            generatedAt: date("2026-02-08T10:00:00Z"),
            lastDailyReset: date("2026-02-08T00:00:00Z"),
            lastWeeklyReset: date("2026-02-02T00:00:00Z"),
            habits: [
                LegacyHabitWidgetHabitRecord(
                    id: UUID(),
                    schedule: .daily,
                    targetPerDay: nil,
                    targetPerWeek: nil,
                    completedCountToday: 1,
                    completedThisWeek: 1
                )
            ]
        )

        let data = try JSONEncoder().encode(legacySnapshot)
        let decoded = try JSONDecoder().decode(HabitWidgetSnapshot.self, from: data)

        XCTAssertEqual(decoded.habits.count, 1)
        XCTAssertNil(decoded.habits[0].title)
        XCTAssertNil(decoded.habits[0].createdAt)
    }

    private func date(_ iso8601: String) -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: iso8601) ?? Date(timeIntervalSince1970: 0)
    }
}

private struct LegacyHabitWidgetSnapshot: Codable {
    let generatedAt: Date
    let lastDailyReset: Date
    let lastWeeklyReset: Date
    let habits: [LegacyHabitWidgetHabitRecord]
}

private struct LegacyHabitWidgetHabitRecord: Codable {
    let id: UUID
    let schedule: HabitWidgetSchedule
    let targetPerDay: Int?
    let targetPerWeek: Int?
    let completedCountToday: Int
    let completedThisWeek: Int
}
