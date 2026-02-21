import UserNotifications
import XCTest
@testable import mochi

@MainActor
final class NotificationManagerTests: XCTestCase {
    func testAuthorizationStatusDelegatesToClient() async {
        let client = MockNotificationCenterClient(status: .provisional)

        let status = await NotificationManager.authorizationStatus(center: client)

        XCTAssertEqual(status, .provisional)
    }

    func testRequestAuthorizationIfNeededReturnsExpectedForExistingStatuses() async {
        let authorized = await NotificationManager.requestAuthorizationIfNeeded(
            center: MockNotificationCenterClient(status: .authorized)
        )
        let provisional = await NotificationManager.requestAuthorizationIfNeeded(
            center: MockNotificationCenterClient(status: .provisional)
        )
        let ephemeral = await NotificationManager.requestAuthorizationIfNeeded(
            center: MockNotificationCenterClient(status: .ephemeral)
        )
        let denied = await NotificationManager.requestAuthorizationIfNeeded(
            center: MockNotificationCenterClient(status: .denied)
        )

        XCTAssertTrue(authorized)
        XCTAssertTrue(provisional)
        XCTAssertTrue(ephemeral)
        XCTAssertFalse(denied)
    }

    func testRequestAuthorizationIfNeededRequestsWhenNotDetermined() async {
        let client = MockNotificationCenterClient(status: .notDetermined)
        client.requestAuthorizationResult = true

        let granted = await NotificationManager.requestAuthorizationIfNeeded(center: client)

        XCTAssertTrue(granted)
        XCTAssertEqual(client.requestAuthorizationCallCount, 1)
    }

    func testRequestAuthorizationIfNeededReturnsFalseWhenRequestThrows() async {
        let client = MockNotificationCenterClient(status: .notDetermined)
        client.requestAuthorizationError = MockError.requestFailed

        let granted = await NotificationManager.requestAuthorizationIfNeeded(center: client)

        XCTAssertFalse(granted)
    }

    func testScheduleDailyReminderCancelsExistingAndAddsExpectedRequest() async throws {
        let client = MockNotificationCenterClient(status: .authorized)

        await NotificationManager.scheduleDailyReminder(hour: 9, minute: 30, center: client)

        let reminderIdentifier = NotificationManager.dailyReminderIdentifier
        XCTAssertEqual(client.removedIdentifiersCalls.count, 1)
        XCTAssertEqual(client.removedIdentifiersCalls.first, [reminderIdentifier])
        XCTAssertEqual(client.addedRequests.count, 1)

        let request = try XCTUnwrap(client.addedRequests.first)
        XCTAssertEqual(request.identifier, reminderIdentifier)
        XCTAssertEqual(request.content.title, "Time for your habits")
        XCTAssertEqual(request.content.body, "Check in with mochi and care for your pet.")

        let trigger = try XCTUnwrap(request.trigger as? UNCalendarNotificationTrigger)
        XCTAssertTrue(trigger.repeats)
        XCTAssertEqual(trigger.dateComponents.hour, 9)
        XCTAssertEqual(trigger.dateComponents.minute, 30)
    }

    func testUpdateDailyReminderRoutesToCancelWhenDisabled() async {
        let client = MockNotificationCenterClient(status: .authorized)

        await NotificationManager.updateDailyReminder(
            enabled: false,
            hour: 8,
            minute: 15,
            center: client
        )

        XCTAssertEqual(client.removedIdentifiersCalls.count, 1)
        XCTAssertTrue(client.addedRequests.isEmpty)
    }

    func testUpdateDailyReminderRoutesToScheduleWhenEnabled() async {
        let client = MockNotificationCenterClient(status: .authorized)

        await NotificationManager.updateDailyReminder(
            enabled: true,
            hour: 7,
            minute: 45,
            center: client
        )

        XCTAssertEqual(client.removedIdentifiersCalls.count, 1)
        XCTAssertEqual(client.addedRequests.count, 1)
        let trigger = try? XCTUnwrap(client.addedRequests.first?.trigger as? UNCalendarNotificationTrigger)
        XCTAssertEqual(trigger?.dateComponents.hour, 7)
        XCTAssertEqual(trigger?.dateComponents.minute, 45)
    }
}

private final class MockNotificationCenterClient: NotificationCenterClient {
    var status: UNAuthorizationStatus
    var requestAuthorizationResult = false
    var requestAuthorizationError: Error?
    var requestAuthorizationCallCount = 0
    var addedRequests: [UNNotificationRequest] = []
    var removedIdentifiersCalls: [[String]] = []

    init(status: UNAuthorizationStatus) {
        self.status = status
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        status
    }

    func requestAuthorization(options _: UNAuthorizationOptions) async throws -> Bool {
        requestAuthorizationCallCount += 1
        if let requestAuthorizationError {
            throw requestAuthorizationError
        }
        return requestAuthorizationResult
    }

    func add(_ request: UNNotificationRequest) async throws {
        addedRequests.append(request)
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        removedIdentifiersCalls.append(identifiers)
    }
}

private enum MockError: Error {
    case requestFailed
}
