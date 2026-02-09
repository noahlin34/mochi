import SwiftUI
import WidgetKit

struct HabitStatusLockScreenWidgetEntryView: View {
    var entry: HabitStatusTimelineProvider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(LockWidgetTheme.iconBubble)
                    Image(systemName: "sparkles")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(LockWidgetTheme.accent)
                }
                .frame(width: 16, height: 16)

                Text("Habits")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(LockWidgetTheme.textPrimary)

                Spacer(minLength: 4)

                Text("\(entry.done)/\(entry.total)")
                    .font(.caption.monospacedDigit().weight(.bold))
                    .foregroundStyle(LockWidgetTheme.textPrimary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(LockWidgetTheme.badgeBackground)
                    )
            }

            LockWidgetProgressBar(progress: completionFraction)

            Text(subtitle)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(LockWidgetTheme.textMuted)
                .lineLimit(1)
        }
        .padding(.vertical, 2)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [LockWidgetTheme.backgroundTop, LockWidgetTheme.backgroundBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
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

    private var completionFraction: Double {
        guard entry.total > 0 else { return 0 }
        return min(1, max(0, Double(entry.done) / Double(entry.total)))
    }
}

private struct LockWidgetProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { proxy in
            let clamped = min(1, max(0, progress))
            let fillWidth = max(4, proxy.size.width * clamped)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(LockWidgetTheme.track)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [LockWidgetTheme.fillStart, LockWidgetTheme.fillEnd],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: fillWidth)
            }
        }
        .frame(height: 6)
    }
}

private enum LockWidgetTheme {
    static let backgroundTop = Color(red: 0.97, green: 0.94, blue: 0.99)
    static let backgroundBottom = Color(red: 0.95, green: 0.97, blue: 0.93)

    static let iconBubble = Color.white.opacity(0.65)
    static let badgeBackground = Color.white.opacity(0.72)

    static let textPrimary = Color(red: 0.20, green: 0.18, blue: 0.24)
    static let textMuted = Color(red: 0.35, green: 0.33, blue: 0.42)
    static let accent = Color(red: 0.53, green: 0.32, blue: 0.76)

    static let track = Color.black.opacity(0.10)
    static let fillStart = Color(red: 0.53, green: 0.32, blue: 0.76)
    static let fillEnd = Color(red: 0.94, green: 0.55, blue: 0.42)
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
