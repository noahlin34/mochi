import Foundation
import SwiftData
import WidgetKit

protocol HabitWidgetSnapshotStoring {
    func save(_ snapshot: HabitWidgetSnapshot)
}

protocol WidgetTimelineReloading {
    func reloadTimelines(ofKind kind: String)
}

struct LiveHabitWidgetSnapshotStore: HabitWidgetSnapshotStoring {
    static let shared = LiveHabitWidgetSnapshotStore()

    func save(_ snapshot: HabitWidgetSnapshot) {
        HabitWidgetSnapshotStore.save(snapshot)
    }
}

struct LiveWidgetTimelineReloader: WidgetTimelineReloading {
    static let shared = LiveWidgetTimelineReloader()

    func reloadTimelines(ofKind kind: String) {
        WidgetCenter.shared.reloadTimelines(ofKind: kind)
    }
}

@MainActor
enum HabitWidgetSyncService {
    static let lockScreenWidgetKind = "habit_status_lockscreen"
    static let homeScreenWidgetKind = "habit_preview_homescreen"

    static func sync(
        context: ModelContext,
        now: () -> Date = Date.init,
        store: HabitWidgetSnapshotStoring = LiveHabitWidgetSnapshotStore.shared,
        reloader: WidgetTimelineReloading = LiveWidgetTimelineReloader.shared
    ) {
        guard let appState = fetchSingle(AppState.self, context: context) else { return }
        let habits = fetchHabits(context: context)

        let snapshot = HabitWidgetSnapshot(
            generatedAt: now(),
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

        store.save(snapshot)
        reloader.reloadTimelines(ofKind: lockScreenWidgetKind)
        reloader.reloadTimelines(ofKind: homeScreenWidgetKind)
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
