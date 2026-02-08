import Foundation
import SwiftData
import WidgetKit

@MainActor
enum HabitWidgetSyncService {
    static let widgetKind = "habit_status_lockscreen"

    static func sync(context: ModelContext) {
        guard let appState = fetchSingle(AppState.self, context: context) else { return }
        let habits = fetchAll(Habit.self, context: context)

        let snapshot = HabitWidgetSnapshot(
            generatedAt: Date(),
            lastDailyReset: appState.lastDailyReset,
            lastWeeklyReset: appState.lastWeeklyReset,
            habits: habits.map { habit in
                HabitWidgetHabitRecord(
                    id: habit.id,
                    schedule: habit.scheduleType.widgetSchedule,
                    targetPerDay: habit.targetPerDay,
                    targetPerWeek: habit.targetPerWeek,
                    completedCountToday: habit.completedCountToday,
                    completedThisWeek: habit.completedThisWeek
                )
            }
        )

        HabitWidgetSnapshotStore.save(snapshot)
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
    }

    private static func fetchSingle<T: PersistentModel>(_ type: T.Type, context: ModelContext) -> T? {
        let descriptor = FetchDescriptor<T>()
        return (try? context.fetch(descriptor))?.first
    }

    private static func fetchAll<T: PersistentModel>(_ type: T.Type, context: ModelContext) -> [T] {
        let descriptor = FetchDescriptor<T>()
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
