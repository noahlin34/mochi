import WidgetKit
import Foundation

struct HabitPreviewEntry: TimelineEntry {
    let date: Date
    let done: Int
    let total: Int
    let rows: [HabitWidgetPreviewRow]
}

struct HabitPreviewTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> HabitPreviewEntry {
        HabitPreviewEntry(
            date: Date(),
            done: 1,
            total: 3,
            rows: [
                HabitWidgetPreviewRow(id: UUID(), title: "Morning walk", progress: 0, target: 1, isDone: false),
                HabitWidgetPreviewRow(id: UUID(), title: "Read 20 pages", progress: 1, target: 1, isDone: true),
                HabitWidgetPreviewRow(id: UUID(), title: "Stretch", progress: 1, target: 2, isDone: false)
            ]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (HabitPreviewEntry) -> Void) {
        completion(makeEntry(at: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HabitPreviewEntry>) -> Void) {
        let now = Date()
        let entry = makeEntry(at: now)
        let nextUpdate = nextTimelineUpdate(after: now)
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func makeEntry(at now: Date) -> HabitPreviewEntry {
        let calendar = Calendar.current
        guard let snapshot = HabitWidgetSnapshotStore.load() else {
            return HabitPreviewEntry(date: now, done: 0, total: 0, rows: [])
        }

        let doneTotal = HabitWidgetListCalculator.computeDoneTotal(
            snapshot: snapshot,
            now: now,
            calendar: calendar
        )
        let rows = HabitWidgetListCalculator.computePreviewRows(
            snapshot: snapshot,
            now: now,
            calendar: calendar,
            limit: 4
        )

        return HabitPreviewEntry(
            date: now,
            done: doneTotal.done,
            total: doneTotal.total,
            rows: rows
        )
    }

    private func nextTimelineUpdate(after now: Date) -> Date {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)
        let nextDay = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? now.addingTimeInterval(86400)
        return calendar.date(byAdding: .minute, value: 1, to: nextDay) ?? nextDay
    }
}
