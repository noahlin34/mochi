import WidgetKit
import Foundation

struct HabitStatusEntry: TimelineEntry {
    let date: Date
    let done: Int
    let total: Int
    let remaining: Int
}

struct HabitStatusTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> HabitStatusEntry {
        HabitStatusEntry(date: Date(), done: 1, total: 3, remaining: 2)
    }

    func getSnapshot(in context: Context, completion: @escaping (HabitStatusEntry) -> Void) {
        completion(makeEntry(at: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HabitStatusEntry>) -> Void) {
        let now = Date()
        let entry = makeEntry(at: now)
        let nextUpdate = nextTimelineUpdate(after: now)
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func makeEntry(at now: Date) -> HabitStatusEntry {
        let calendar = Calendar.current
        guard let snapshot = HabitWidgetSnapshotStore.load() else {
            return HabitStatusEntry(date: now, done: 0, total: 0, remaining: 0)
        }

        let progress = HabitWidgetProgressCalculator.computeDisplayProgress(
            snapshot: snapshot,
            now: now,
            calendar: calendar
        )

        return HabitStatusEntry(
            date: now,
            done: progress.done,
            total: progress.total,
            remaining: progress.remaining
        )
    }

    private func nextTimelineUpdate(after now: Date) -> Date {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)
        let nextDay = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? now.addingTimeInterval(86400)
        return calendar.date(byAdding: .minute, value: 1, to: nextDay) ?? nextDay
    }
}
