import SwiftUI
import WidgetKit

struct HabitPreviewHomeWidgetEntryView: View {
    var entry: HabitPreviewTimelineProvider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header

            if entry.total == 0 {
                Text("No habits yet")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(HabitWidgetTheme.textMuted)
                    .padding(.top, 4)
                    .frame(maxHeight: .infinity, alignment: .topLeading)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(entry.rows.enumerated()), id: \.element.id) { index, row in
                        HabitPreviewRowView(row: row, index: index)
                    }
                }
                .frame(maxHeight: .infinity, alignment: .top)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(for: .widget) {
            HabitWidgetBackgroundView()
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(HabitWidgetTheme.iconBubble)
                Image(systemName: "sparkles")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(HabitWidgetTheme.accentPurple)
            }
            .frame(width: 20, height: 20)

            Text("Today's Habits")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(HabitWidgetTheme.textPrimary)

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 0) {
                Text("\(entry.done)/\(entry.total)")
                    .font(.headline.weight(.black))
                    .foregroundStyle(HabitWidgetTheme.textPrimary)
                Text("done")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(HabitWidgetTheme.textMuted)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(HabitWidgetTheme.badgeBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(HabitWidgetTheme.badgeBorder, lineWidth: 0.75)
            )
        }
    }
}

private struct HabitPreviewRowView: View {
    let row: HabitWidgetPreviewRow
    let index: Int

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: row.isDone ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(row.isDone ? HabitWidgetTheme.doneIcon : HabitWidgetTheme.incompleteIcon)
                .font(.caption.weight(.bold))

            Text(row.title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(HabitWidgetTheme.textPrimary)
                .lineLimit(1)

            Spacer(minLength: 8)

            Text("\(row.progress)/\(row.target)")
                .font(.caption2.monospacedDigit().weight(.bold))
                .foregroundStyle(HabitWidgetTheme.textPrimary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(HabitWidgetTheme.progressBadge)
                )
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(rowBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(HabitWidgetTheme.rowBorder, lineWidth: 0.5)
        )
    }

    private var rowBackground: LinearGradient {
        if row.isDone {
            return LinearGradient(
                colors: [HabitWidgetTheme.doneRowStart, HabitWidgetTheme.doneRowEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        let palettes: [(Color, Color)] = [
            (HabitWidgetTheme.pendingRowAStart, HabitWidgetTheme.pendingRowAEnd),
            (HabitWidgetTheme.pendingRowBStart, HabitWidgetTheme.pendingRowBEnd),
            (HabitWidgetTheme.pendingRowCStart, HabitWidgetTheme.pendingRowCEnd),
            (HabitWidgetTheme.pendingRowDStart, HabitWidgetTheme.pendingRowDEnd)
        ]
        let palette = palettes[index % palettes.count]
        return LinearGradient(colors: [palette.0, palette.1], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

private struct HabitWidgetBackgroundView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [HabitWidgetTheme.backgroundTop, HabitWidgetTheme.backgroundBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(HabitWidgetTheme.glowPurple)
                .frame(width: 140, height: 140)
                .offset(x: 95, y: -65)

            Circle()
                .fill(HabitWidgetTheme.glowPeach)
                .frame(width: 110, height: 110)
                .offset(x: -110, y: 70)
        }
    }
}

private enum HabitWidgetTheme {
    static let backgroundTop = Color(red: 0.99, green: 0.97, blue: 0.94)
    static let backgroundBottom = Color(red: 0.95, green: 0.90, blue: 0.98)
    static let glowPurple = Color(red: 0.85, green: 0.77, blue: 0.95).opacity(0.55)
    static let glowPeach = Color(red: 0.99, green: 0.88, blue: 0.80).opacity(0.7)

    static let textPrimary = Color(red: 0.20, green: 0.18, blue: 0.24)
    static let textMuted = Color(red: 0.35, green: 0.32, blue: 0.42)
    static let accentPurple = Color(red: 0.53, green: 0.32, blue: 0.76)

    static let iconBubble = Color.white.opacity(0.7)
    static let badgeBackground = Color.white.opacity(0.55)
    static let badgeBorder = Color.white.opacity(0.8)
    static let rowBorder = Color.white.opacity(0.45)

    static let progressBadge = Color.white.opacity(0.65)
    static let doneIcon = Color(red: 0.26, green: 0.69, blue: 0.42)
    static let incompleteIcon = Color(red: 0.53, green: 0.32, blue: 0.76)

    static let pendingRowAStart = Color(red: 0.99, green: 0.93, blue: 0.74)
    static let pendingRowAEnd = Color(red: 0.98, green: 0.89, blue: 0.66)
    static let pendingRowBStart = Color(red: 0.86, green: 0.79, blue: 0.94)
    static let pendingRowBEnd = Color(red: 0.81, green: 0.73, blue: 0.91)
    static let pendingRowCStart = Color(red: 0.82, green: 0.93, blue: 0.85)
    static let pendingRowCEnd = Color(red: 0.75, green: 0.89, blue: 0.80)
    static let pendingRowDStart = Color(red: 0.99, green: 0.87, blue: 0.80)
    static let pendingRowDEnd = Color(red: 0.98, green: 0.82, blue: 0.72)

    static let doneRowStart = Color(red: 0.85, green: 0.95, blue: 0.87)
    static let doneRowEnd = Color(red: 0.79, green: 0.91, blue: 0.82)
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
