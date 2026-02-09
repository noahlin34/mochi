import Foundation

struct HabitWidgetSnapshot: Codable, Equatable {
    let generatedAt: Date
    let lastDailyReset: Date
    let lastWeeklyReset: Date
    let habits: [HabitWidgetHabitRecord]
}

struct HabitWidgetHabitRecord: Codable, Equatable {
    let id: UUID
    let title: String?
    let createdAt: Date?
    let schedule: HabitWidgetSchedule
    let targetPerDay: Int?
    let targetPerWeek: Int?
    let completedCountToday: Int
    let completedThisWeek: Int

    init(
        id: UUID,
        title: String? = nil,
        createdAt: Date? = nil,
        schedule: HabitWidgetSchedule,
        targetPerDay: Int?,
        targetPerWeek: Int?,
        completedCountToday: Int,
        completedThisWeek: Int
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.schedule = schedule
        self.targetPerDay = targetPerDay
        self.targetPerWeek = targetPerWeek
        self.completedCountToday = completedCountToday
        self.completedThisWeek = completedThisWeek
    }
}

enum HabitWidgetSchedule: String, Codable {
    case daily
    case weekly
    case xTimesPerDay
    case xTimesPerWeek
}
