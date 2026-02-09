import SwiftUI
import WidgetKit

struct HabitPreviewHomeWidgetEntryView: View {
    var entry: HabitPreviewTimelineProvider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Today's Habits")
                    .font(.headline)
                Spacer()
                Text("\(entry.done)/\(entry.total)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            if entry.total == 0 {
                Text("No habits yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxHeight: .infinity, alignment: .topLeading)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(entry.rows, id: \.id) { row in
                        HabitPreviewRowView(row: row)
                    }
                }
                .frame(maxHeight: .infinity, alignment: .top)
            }
        }
        .padding(.vertical, 2)
    }
}

private struct HabitPreviewRowView: View {
    let row: HabitWidgetPreviewRow

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: row.isDone ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(row.isDone ? .green : .secondary)
                .font(.caption)

            Text(row.title)
                .font(.caption)
                .lineLimit(1)

            Spacer(minLength: 8)

            Text("\(row.progress)/\(row.target)")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }
}

struct HabitPreviewHomeWidget: Widget {
    let kind: String = "habit_preview_homescreen"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HabitPreviewTimelineProvider()) { entry in
            HabitPreviewHomeWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Habit Preview")
        .description("Preview your habit list and completion status.")
        .supportedFamilies([.systemMedium])
    }
}

#Preview(as: .systemMedium) {
    HabitPreviewHomeWidget()
} timeline: {
    HabitPreviewEntry(
        date: .now,
        done: 0,
        total: 0,
        rows: []
    )
    HabitPreviewEntry(
        date: .now,
        done: 2,
        total: 4,
        rows: [
            HabitWidgetPreviewRow(id: UUID(), title: "Study 30 min", progress: 0, target: 1, isDone: false),
            HabitWidgetPreviewRow(id: UUID(), title: "Drink water", progress: 2, target: 3, isDone: false),
            HabitWidgetPreviewRow(id: UUID(), title: "Walk", progress: 1, target: 1, isDone: true),
            HabitWidgetPreviewRow(id: UUID(), title: "Meditate", progress: 1, target: 1, isDone: true)
        ]
    )
}
