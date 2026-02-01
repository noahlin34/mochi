import Foundation

enum ScheduleType: String, Codable, CaseIterable, Identifiable {
    case daily
    case xTimesPerWeek

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .daily:
            return "Daily"
        case .xTimesPerWeek:
            return "X times per week"
        }
    }
}

enum PetSpecies: String, Codable, CaseIterable, Identifiable {
    case cat
    case dog
    case bunny

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
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
