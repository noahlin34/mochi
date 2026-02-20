import Foundation
import UserNotifications

protocol NotificationCenterClient {
    func authorizationStatus() async -> UNAuthorizationStatus
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
    func add(_ request: UNNotificationRequest) async throws
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])
}

struct LiveNotificationCenterClient: NotificationCenterClient {
    static let shared = LiveNotificationCenterClient()

    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        try await center.requestAuthorization(options: options)
    }

    func add(_ request: UNNotificationRequest) async throws {
        try await center.add(request)
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}

enum NotificationManager {
    static let dailyReminderIdentifier = "daily_habit_reminder"

    static func authorizationStatus(
        center: NotificationCenterClient = LiveNotificationCenterClient.shared
    ) async -> UNAuthorizationStatus {
        await center.authorizationStatus()
    }

    static func updateDailyReminder(
        enabled: Bool,
        hour: Int,
        minute: Int,
        center: NotificationCenterClient = LiveNotificationCenterClient.shared
    ) async {
        if enabled {
            await scheduleDailyReminder(hour: hour, minute: minute, center: center)
        } else {
            await cancelDailyReminder(center: center)
        }
    }

    static func requestAuthorizationIfNeeded(
        center: NotificationCenterClient = LiveNotificationCenterClient.shared
    ) async -> Bool {
        switch await center.authorizationStatus() {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            do {
                return try await center.requestAuthorization(options: [.alert, .sound, .badge])
            } catch {
                return false
            }
        @unknown default:
            return false
        }
    }

    static func scheduleDailyReminder(
        hour: Int,
        minute: Int,
        center: NotificationCenterClient = LiveNotificationCenterClient.shared
    ) async {
        await cancelDailyReminder(center: center)

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let content = UNMutableNotificationContent()
        content.title = "Time for your habits"
        content.body = "Check in with mochi and care for your pet."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: dailyReminderIdentifier,
            content: content,
            trigger: trigger
        )

        try? await center.add(request)
    }

    static func cancelDailyReminder(
        center: NotificationCenterClient = LiveNotificationCenterClient.shared
    ) async {
        center.removePendingNotificationRequests(withIdentifiers: [dailyReminderIdentifier])
    }
}
