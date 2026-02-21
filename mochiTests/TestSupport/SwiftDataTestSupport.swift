import Foundation
import SwiftData
@testable import mochi

enum SwiftDataTestSupport {
    @MainActor
    static func makeInMemoryContext() throws -> ModelContext {
        let schema = Schema([
            Habit.self,
            Pet.self,
            InventoryItem.self,
            AppState.self
        ])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: configuration)
        return container.mainContext
    }

    static func utcCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return calendar
    }

    static func date(_ iso8601String: String) -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: iso8601String) {
            return date
        }

        formatter.formatOptions = [.withInternetDateTime]
        guard let fallbackDate = formatter.date(from: iso8601String) else {
            fatalError("Invalid ISO8601 date string: \(iso8601String)")
        }
        return fallbackDate
    }
}
