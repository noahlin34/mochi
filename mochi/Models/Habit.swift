import Foundation
import SwiftData

@Model
final class Habit {
    var id: UUID
    var title: String
    var scheduleType: ScheduleType
    var targetPerDay: Int?
    var targetPerWeek: Int?
    var completedCountToday: Int
    var completedThisWeek: Int
    var lastCompletedDate: Date?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        scheduleType: ScheduleType,
        targetPerDay: Int? = nil,
        targetPerWeek: Int? = nil,
        completedCountToday: Int = 0,
        completedThisWeek: Int = 0,
        lastCompletedDate: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.scheduleType = scheduleType
        self.targetPerDay = targetPerDay
        self.targetPerWeek = targetPerWeek
        self.completedCountToday = completedCountToday
        self.completedThisWeek = completedThisWeek
        self.lastCompletedDate = lastCompletedDate
        self.createdAt = createdAt
    }
}

extension Habit {
    var targetForSchedule: Int {
        switch scheduleType {
        case .daily, .weekly:
            return 1
        case .xTimesPerDay:
            return max(1, targetPerDay ?? 1)
        case .xTimesPerWeek:
            return max(1, targetPerWeek ?? 1)
        }
    }

    var progressForSchedule: Int {
        switch scheduleType {
        case .daily, .xTimesPerDay:
            return completedCountToday
        case .weekly, .xTimesPerWeek:
            return completedThisWeek
        }
    }

    var isGoalMetForSchedule: Bool {
        progressForSchedule >= targetForSchedule
    }
}
