import Foundation

enum HabitWidgetSnapshotStore {
    static let appGroupIdentifier = "group.com.noahlin.mochi"
    static let snapshotKey = "habit_widget_snapshot_v1"

    static func save(_ snapshot: HabitWidgetSnapshot) {
        save(snapshot, defaults: UserDefaults(suiteName: appGroupIdentifier))
    }

    static func load() -> HabitWidgetSnapshot? {
        load(defaults: UserDefaults(suiteName: appGroupIdentifier))
    }

    static func save(_ snapshot: HabitWidgetSnapshot, defaults: UserDefaults?) {
        guard let defaults else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        guard let data = try? encoder.encode(snapshot) else { return }
        defaults.set(data, forKey: snapshotKey)
    }

    static func load(defaults: UserDefaults?) -> HabitWidgetSnapshot? {
        guard let defaults else { return nil }
        guard let data = defaults.data(forKey: snapshotKey) else { return nil }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(HabitWidgetSnapshot.self, from: data)
    }
}
