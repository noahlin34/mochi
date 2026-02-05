import Foundation
import UserNotifications

enum NotificationManager {
    static let dailyReminderIdentifier = "daily_habit_reminder"

    static func updateDailyReminder(enabled: Bool, hour: Int, minute: Int) async {
        if enabled {
            await scheduleDailyReminder(hour: hour, minute: minute)
        } else {
            await cancelDailyReminder()
        }
    }

    static func requestAuthorizationIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
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

    static func scheduleDailyReminder(hour: Int, minute: Int) async {
        let center = UNUserNotificationCenter.current()
        await cancelDailyReminder()

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

    static func cancelDailyReminder() async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [dailyReminderIdentifier])
    }
}
