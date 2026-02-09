import Foundation

struct HabitWidgetPreviewRow: Equatable {
    let id: UUID
    let title: String
    let progress: Int
    let target: Int
    let isDone: Bool
}

enum HabitWidgetListCalculator {
    static func computePreviewRows(
        snapshot: HabitWidgetSnapshot,
        now: Date,
        calendar: Calendar,
        limit: Int
    ) -> [HabitWidgetPreviewRow] {
        let effectiveLimit = max(0, limit)
        guard effectiveLimit > 0 else { return [] }

        let projection = makeProjection(snapshot: snapshot, now: now, calendar: calendar)

        return snapshot.habits
            .map { habit in
                let target = targetForHabit(habit)
                let progress = effectiveProgress(habit, projection: projection)
                return (
                    row: HabitWidgetPreviewRow(
                        id: habit.id,
                        title: normalizedTitle(from: habit.title),
                        progress: progress,
                        target: target,
                        isDone: progress >= target
                    ),
                    createdAt: habit.createdAt ?? .distantPast
                )
            }
            .sorted { lhs, rhs in
                if lhs.row.isDone != rhs.row.isDone {
                    return lhs.row.isDone == false
                }
                if lhs.createdAt != rhs.createdAt {
                    return lhs.createdAt < rhs.createdAt
                }
                return lhs.row.id.uuidString < rhs.row.id.uuidString
            }
            .prefix(effectiveLimit)
            .map { $0.row }
    }

    static func computeDoneTotal(
        snapshot: HabitWidgetSnapshot,
        now: Date,
        calendar: Calendar
    ) -> (done: Int, total: Int) {
        let progress = HabitWidgetProgressCalculator.computeDisplayProgress(
            snapshot: snapshot,
            now: now,
            calendar: calendar
        )
        return (done: progress.done, total: progress.total)
    }

    private static func makeProjection(
        snapshot: HabitWidgetSnapshot,
        now: Date,
        calendar: Calendar
    ) -> (dailyReset: Bool, weeklyReset: Bool) {
        let startOfToday = calendar.startOfDay(for: now)
        let snapshotDailyReset = calendar.startOfDay(for: snapshot.lastDailyReset)
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? startOfToday
        let snapshotWeeklyReset = calendar.dateInterval(of: .weekOfYear, for: snapshot.lastWeeklyReset)?.start ?? startOfWeek

        return (
            dailyReset: startOfToday > snapshotDailyReset,
            weeklyReset: startOfWeek > snapshotWeeklyReset
        )
    }

    private static func targetForHabit(_ habit: HabitWidgetHabitRecord) -> Int {
        switch habit.schedule {
        case .daily, .weekly:
            return 1
        case .xTimesPerDay:
            return max(1, habit.targetPerDay ?? 1)
        case .xTimesPerWeek:
            return max(1, habit.targetPerWeek ?? 1)
        }
    }

    private static func effectiveProgress(
        _ habit: HabitWidgetHabitRecord,
        projection: (dailyReset: Bool, weeklyReset: Bool)
    ) -> Int {
        switch habit.schedule {
        case .daily, .xTimesPerDay:
            return projection.dailyReset ? 0 : habit.completedCountToday
        case .weekly, .xTimesPerWeek:
            return projection.weeklyReset ? 0 : habit.completedThisWeek
        }
    }

    private static func normalizedTitle(from rawTitle: String?) -> String {
        let trimmed = rawTitle?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "Untitled Habit" : trimmed
    }
}
