import SwiftUI
import WidgetKit

struct HabitStatusLockScreenWidgetEntryView: View {
    var entry: HabitStatusTimelineProvider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Habits: \(entry.done)/\(entry.total)")
                .font(.headline)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var subtitle: String {
        if entry.total == 0 {
            return "No habits yet"
        }
        if entry.remaining == 0 {
            return "All done for today"
        }
        return "\(entry.remaining) left today"
    }
}

struct HabitStatusLockScreenWidget: Widget {
    let kind: String = "habit_status_lockscreen"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HabitStatusTimelineProvider()) { entry in
            HabitStatusLockScreenWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Habit Status")
        .description("See how many habits are done today.")
        .supportedFamilies([.accessoryRectangular])
    }
}

#Preview(as: .accessoryRectangular) {
    HabitStatusLockScreenWidget()
} timeline: {
    HabitStatusEntry(date: .now, done: 0, total: 0, remaining: 0)
    HabitStatusEntry(date: .now, done: 2, total: 4, remaining: 2)
    HabitStatusEntry(date: .now, done: 4, total: 4, remaining: 0)
}
