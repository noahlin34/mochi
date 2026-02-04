import Foundation

enum ScheduleType: String, Codable, CaseIterable, Identifiable {
    case daily
    case weekly
    case xTimesPerDay
    case xTimesPerWeek

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .daily:
            return "Daily"
        case .weekly:
            return "Weekly"
        case .xTimesPerDay:
            return "X times per day"
        case .xTimesPerWeek:
            return "X times per week"
        }
    }

    var isDailyCounter: Bool {
        self == .daily || self == .xTimesPerDay
    }

    var isWeeklyCounter: Bool {
        self == .weekly || self == .xTimesPerWeek
    }

    var needsDailyTarget: Bool {
        self == .xTimesPerDay
    }

    var needsWeeklyTarget: Bool {
        self == .xTimesPerWeek
    }
}

enum PetSpecies: String, Codable, CaseIterable, Identifiable {
    case cat
    case dog
    case bunny
    case penguin
    case lion

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cat, .dog, .bunny, .lion:
            return rawValue.capitalized
        case .penguin:
            return "Penguin"
        }
    }
}

enum InventoryItemType: String, Codable, CaseIterable, Identifiable {
    case outfit
    case room

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }
}
