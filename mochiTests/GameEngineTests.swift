import XCTest
@testable import mochi

final class GameEngineTests: XCTestCase {
    private var calendar: Calendar!

    override func setUp() {
        super.setUp()
        calendar = SwiftDataTestSupport.utcCalendar()
    }

    @MainActor
    func testCompleteDailyHabitAwardsRewardAndInitialStreak() {
        let now = SwiftDataTestSupport.date("2026-02-10T10:00:00Z")
        let engine = GameEngine(calendar: calendar, dateProvider: { now })

        let habit = Habit(title: "Read", scheduleType: .daily)
        let pet = Pet(name: "Mochi", species: .dog, energy: 50, hunger: 50, cleanliness: 50, coins: 0)
        let startOfToday = calendar.startOfDay(for: now)
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? startOfToday
        let appState = AppState(
            lastDailyReset: startOfToday,
            lastWeeklyReset: startOfWeek,
            currentStreak: 0
        )

        let completed = engine.completeHabit(habit, pet: pet, appState: appState)

        XCTAssertTrue(completed)
        XCTAssertEqual(habit.completedCountToday, 1)
        XCTAssertEqual(habit.completedThisWeek, 1)
        XCTAssertEqual(habit.lastCompletedDate, now)

        XCTAssertEqual(pet.energy, 53)
        XCTAssertEqual(pet.hunger, 55)
        XCTAssertEqual(pet.cleanliness, 50)
        XCTAssertEqual(pet.coins, 4)
        XCTAssertEqual(pet.xp, 10)
        XCTAssertEqual(pet.level, 1)

        XCTAssertEqual(appState.currentStreak, 1)
        XCTAssertEqual(appState.lastStreakBonusDate, now)
    }

    @MainActor
    func testCompleteXTimesPerDayOnlyAwardsRewardAtTarget() {
        let now = SwiftDataTestSupport.date("2026-02-10T10:00:00Z")
        let engine = GameEngine(calendar: calendar, dateProvider: { now })

        let habit = Habit(title: "Walk", scheduleType: .xTimesPerDay, targetPerDay: 2)
        let pet = Pet(name: "Mochi", species: .dog, energy: 80, hunger: 80, cleanliness: 80, coins: 0)

        XCTAssertTrue(engine.completeHabit(habit, pet: pet))
        XCTAssertEqual(habit.completedCountToday, 1)
        XCTAssertEqual(habit.completedThisWeek, 1)
        XCTAssertEqual(pet.xp, 0)
        XCTAssertEqual(pet.coins, 0)

        XCTAssertTrue(engine.completeHabit(habit, pet: pet))
        XCTAssertEqual(habit.completedCountToday, 2)
        XCTAssertEqual(habit.completedThisWeek, 2)
        XCTAssertEqual(pet.xp, 10)
        XCTAssertEqual(pet.coins, 5)

        XCTAssertFalse(engine.completeHabit(habit, pet: pet))
    }

    @MainActor
    func testStreakBonusAppliedOnlyOncePerDay() {
        let now = SwiftDataTestSupport.date("2026-02-10T12:00:00Z")
        let engine = GameEngine(calendar: calendar, dateProvider: { now })

        let daily = Habit(title: "Daily", scheduleType: .daily)
        let weekly = Habit(title: "Weekly", scheduleType: .weekly)
        let pet = Pet(name: "Mochi", species: .dog, energy: 100, hunger: 100, cleanliness: 100, coins: 0)
        let startOfToday = calendar.startOfDay(for: now)
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? startOfToday
        let appState = AppState(
            lastDailyReset: startOfToday,
            lastWeeklyReset: startOfWeek,
            currentStreak: 2
        )

        XCTAssertTrue(engine.completeHabit(daily, pet: pet, appState: appState))
        XCTAssertTrue(engine.completeHabit(weekly, pet: pet, appState: appState))

        XCTAssertEqual(pet.coins, 12)
        XCTAssertEqual(pet.xp, 20)
        XCTAssertEqual(appState.lastStreakBonusDate, now)
    }

    @MainActor
    func testRunResetsIfNeededAppliesDailyDecayAndIncrementsStreakWhenCompletedYesterday() {
        let now = SwiftDataTestSupport.date("2026-01-08T10:00:00Z")
        let yesterday = SwiftDataTestSupport.date("2026-01-07T20:00:00Z")
        let engine = GameEngine(calendar: calendar, dateProvider: { now })

        let habit = Habit(
            title: "Read",
            scheduleType: .daily,
            completedCountToday: 1,
            completedThisWeek: 3,
            lastCompletedDate: yesterday
        )
        let pet = Pet(name: "Mochi", species: .dog, energy: 80, hunger: 80, cleanliness: 80)
        let appState = AppState(
            lastDailyReset: SwiftDataTestSupport.date("2026-01-07T00:00:00Z"),
            lastWeeklyReset: SwiftDataTestSupport.date("2026-01-05T00:00:00Z"),
            currentStreak: 4
        )

        engine.runResetsIfNeeded(appState: appState, habits: [habit], pet: pet)

        XCTAssertEqual(appState.currentStreak, 5)
        XCTAssertEqual(habit.completedCountToday, 0)
        XCTAssertEqual(habit.completedThisWeek, 3)
        XCTAssertEqual(appState.lastDailyReset, SwiftDataTestSupport.date("2026-01-08T00:00:00Z"))

        XCTAssertEqual(pet.hunger, 68)
        XCTAssertEqual(pet.cleanliness, 74)
        XCTAssertEqual(pet.energy, 60)
    }

    @MainActor
    func testRunResetsIfNeededResetsStreakAndEnergyWhenDayGapIsMoreThanOne() {
        let now = SwiftDataTestSupport.date("2026-01-08T10:00:00Z")
        let engine = GameEngine(calendar: calendar, dateProvider: { now })

        let habit = Habit(
            title: "Walk",
            scheduleType: .daily,
            completedCountToday: 1,
            completedThisWeek: 2,
            lastCompletedDate: SwiftDataTestSupport.date("2026-01-06T12:00:00Z")
        )
        let pet = Pet(name: "Mochi", species: .dog, energy: 70, hunger: 50, cleanliness: 40)
        let appState = AppState(
            lastDailyReset: SwiftDataTestSupport.date("2026-01-05T00:00:00Z"),
            lastWeeklyReset: SwiftDataTestSupport.date("2026-01-05T00:00:00Z"),
            currentStreak: 3
        )

        engine.runResetsIfNeeded(appState: appState, habits: [habit], pet: pet)

        XCTAssertEqual(appState.currentStreak, 0)
        XCTAssertEqual(pet.hunger, 38)
        XCTAssertEqual(pet.cleanliness, 34)
        XCTAssertEqual(pet.energy, 0)
    }

    @MainActor
    func testRunResetsIfNeededResetsWeeklyCountersOnNewWeek() {
        let now = SwiftDataTestSupport.date("2026-01-12T10:00:00Z")
        let engine = GameEngine(calendar: calendar, dateProvider: { now })

        let habit = Habit(
            title: "Walk",
            scheduleType: .xTimesPerWeek,
            targetPerWeek: 4,
            completedCountToday: 1,
            completedThisWeek: 4,
            lastCompletedDate: SwiftDataTestSupport.date("2026-01-11T19:00:00Z")
        )
        let pet = Pet(name: "Mochi", species: .dog, energy: 80, hunger: 80, cleanliness: 80)
        let appState = AppState(
            lastDailyReset: SwiftDataTestSupport.date("2026-01-11T00:00:00Z"),
            lastWeeklyReset: SwiftDataTestSupport.date("2026-01-05T00:00:00Z"),
            currentStreak: 1
        )

        engine.runResetsIfNeeded(appState: appState, habits: [habit], pet: pet)

        XCTAssertEqual(habit.completedThisWeek, 0)
        XCTAssertEqual(appState.lastWeeklyReset, SwiftDataTestSupport.date("2026-01-12T00:00:00Z"))
    }
}
