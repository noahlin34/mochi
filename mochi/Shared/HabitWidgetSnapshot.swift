import Foundation

struct HabitWidgetSnapshot: Codable, Equatable {
    let generatedAt: Date
    let lastDailyReset: Date
    let lastWeeklyReset: Date
    let habits: [HabitWidgetHabitRecord]
}

struct HabitWidgetHabitRecord: Codable, Equatable {
    let id: UUID
    let schedule: HabitWidgetSchedule
    let targetPerDay: Int?
    let targetPerWeek: Int?
    let completedCountToday: Int
    let completedThisWeek: Int
}

enum HabitWidgetSchedule: String, Codable {
    case daily
    case weekly
    case xTimesPerDay
    case xTimesPerWeek
}
