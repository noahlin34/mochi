import Foundation
import SwiftData

@Model
final class Habit {
    var id: UUID
    var title: String
    var scheduleType: ScheduleType
    var targetPerWeek: Int?
    var completedCountToday: Int
    var completedThisWeek: Int
    var lastCompletedDate: Date?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        scheduleType: ScheduleType,
        targetPerWeek: Int? = nil,
        completedCountToday: Int = 0,
        completedThisWeek: Int = 0,
        lastCompletedDate: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.scheduleType = scheduleType
        self.targetPerWeek = targetPerWeek
        self.completedCountToday = completedCountToday
        self.completedThisWeek = completedThisWeek
        self.lastCompletedDate = lastCompletedDate
        self.createdAt = createdAt
    }
}
