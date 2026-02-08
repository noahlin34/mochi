import Foundation

enum HabitWidgetProgressCalculator {
    static func computeDisplayProgress(
        snapshot: HabitWidgetSnapshot,
        now: Date,
        calendar: Calendar
    ) -> (done: Int, total: Int, remaining: Int) {
        let startOfToday = calendar.startOfDay(for: now)
        let snapshotDailyReset = calendar.startOfDay(for: snapshot.lastDailyReset)
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? startOfToday
        let snapshotWeeklyReset = calendar.dateInterval(of: .weekOfYear, for: snapshot.lastWeeklyReset)?.start ?? startOfWeek

        let shouldProjectDailyReset = startOfToday > snapshotDailyReset
        let shouldProjectWeeklyReset = startOfWeek > snapshotWeeklyReset

        let done = snapshot.habits.filter { habit in
            isHabitDone(
                habit,
                shouldProjectDailyReset: shouldProjectDailyReset,
                shouldProjectWeeklyReset: shouldProjectWeeklyReset
            )
        }.count

        let total = snapshot.habits.count
        let remaining = max(0, total - done)
        return (done: done, total: total, remaining: remaining)
    }

    private static func isHabitDone(
        _ habit: HabitWidgetHabitRecord,
        shouldProjectDailyReset: Bool,
        shouldProjectWeeklyReset: Bool
    ) -> Bool {
        switch habit.schedule {
        case .daily:
            return effectiveDailyCount(habit, shouldProjectDailyReset: shouldProjectDailyReset) >= 1

        case .weekly:
            return effectiveWeeklyCount(habit, shouldProjectWeeklyReset: shouldProjectWeeklyReset) >= 1

        case .xTimesPerDay:
            let target = max(1, habit.targetPerDay ?? 1)
            return effectiveDailyCount(habit, shouldProjectDailyReset: shouldProjectDailyReset) >= target

        case .xTimesPerWeek:
            let target = max(1, habit.targetPerWeek ?? 1)
            return effectiveWeeklyCount(habit, shouldProjectWeeklyReset: shouldProjectWeeklyReset) >= target
        }
    }

    private static func effectiveDailyCount(
        _ habit: HabitWidgetHabitRecord,
        shouldProjectDailyReset: Bool
    ) -> Int {
        shouldProjectDailyReset ? 0 : habit.completedCountToday
    }

    private static func effectiveWeeklyCount(
        _ habit: HabitWidgetHabitRecord,
        shouldProjectWeeklyReset: Bool
    ) -> Int {
        shouldProjectWeeklyReset ? 0 : habit.completedThisWeek
    }
}
