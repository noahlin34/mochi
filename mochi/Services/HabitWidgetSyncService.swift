import Foundation
import SwiftData
import WidgetKit

@MainActor
enum HabitWidgetSyncService {
    static let lockScreenWidgetKind = "habit_status_lockscreen"
    static let homeScreenWidgetKind = "habit_preview_homescreen"

    static func sync(context: ModelContext) {
        guard let appState = fetchSingle(AppState.self, context: context) else { return }
        let habits = fetchHabits(context: context)

        let snapshot = HabitWidgetSnapshot(
            generatedAt: Date(),
            lastDailyReset: appState.lastDailyReset,
            lastWeeklyReset: appState.lastWeeklyReset,
            habits: habits.map { habit in
                HabitWidgetHabitRecord(
                    id: habit.id,
                    title: habit.title,
                    createdAt: habit.createdAt,
                    schedule: habit.scheduleType.widgetSchedule,
                    targetPerDay: habit.targetPerDay,
                    targetPerWeek: habit.targetPerWeek,
                    completedCountToday: habit.completedCountToday,
                    completedThisWeek: habit.completedThisWeek
                )
            }
        )

        HabitWidgetSnapshotStore.save(snapshot)
        WidgetCenter.shared.reloadTimelines(ofKind: lockScreenWidgetKind)
        WidgetCenter.shared.reloadTimelines(ofKind: homeScreenWidgetKind)
    }

    private static func fetchSingle<T: PersistentModel>(_ type: T.Type, context: ModelContext) -> T? {
        let descriptor = FetchDescriptor<T>()
        return (try? context.fetch(descriptor))?.first
    }

    private static func fetchHabits(context: ModelContext) -> [Habit] {
        let descriptor = FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.createdAt, order: .forward)])
        return (try? context.fetch(descriptor)) ?? []
    }
}

private extension ScheduleType {
    var widgetSchedule: HabitWidgetSchedule {
        switch self {
        case .daily:
            return .daily
        case .weekly:
            return .weekly
        case .xTimesPerDay:
            return .xTimesPerDay
        case .xTimesPerWeek:
            return .xTimesPerWeek
        }
    }
}
