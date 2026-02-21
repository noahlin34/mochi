import RevenueCat
import XCTest
@testable import mochi

final class RevenueCatManagerTests: XCTestCase {
    @MainActor
    func testConfigureSDKIfNeededConfiguresClientWhenNeeded() {
        let client = MockPurchasesClient()
        client.isConfiguredValue = false

        RevenueCatManager.configureSDKIfNeeded(purchasesClient: client)

        XCTAssertEqual(client.setLogLevelCallCount, 1)
        XCTAssertEqual(client.configureCallCount, 1)
        XCTAssertEqual(client.lastConfiguredAPIKey, RevenueCatManager.apiKey)
    }

    @MainActor
    func testConfigureSDKIfNeededSkipsConfigureWhenAlreadyConfigured() {
        let client = MockPurchasesClient()
        client.isConfiguredValue = true

        RevenueCatManager.configureSDKIfNeeded(purchasesClient: client)

        XCTAssertEqual(client.setLogLevelCallCount, 1)
        XCTAssertEqual(client.configureCallCount, 0)
    }

    @MainActor
    func testStartIsIdempotent() async {
        let client = MockPurchasesClient()
        client.customerInfoResult = .success(makeCustomerInfo(hasMochiPro: false))
        client.currentOfferingResult = .success(nil)
        let manager = RevenueCatManager(purchasesClient: client)

        manager.start()
        manager.start()

        await assertEventually {
            client.customerInfoCallCount == 1 && client.currentOfferingCallCount == 1
        }
    }

    @MainActor
    func testStartLoadsInitialStateAndProcessesCustomerInfoStream() async {
        let client = MockPurchasesClient()
        client.customerInfoResult = .success(makeCustomerInfo(hasMochiPro: false))
        client.currentOfferingResult = .success(makeOffering())
        let manager = RevenueCatManager(purchasesClient: client)

        manager.start()

        await assertEventually {
            manager.currentOffering?.identifier == "main"
        }
        XCTAssertFalse(manager.hasMochiPro)

        client.emitCustomerInfo(makeCustomerInfo(hasMochiPro: true))

        await assertEventually {
            manager.hasMochiPro
        }
    }

    @MainActor
    func testRefreshCustomerInfoSetsFallbackErrorWhenRequestFails() async {
        let client = MockPurchasesClient()
        client.customerInfoResult = .failure(MockError.network)
        let manager = RevenueCatManager(purchasesClient: client)

        await manager.refreshCustomerInfo()

        XCTAssertEqual(manager.lastErrorMessage, MockError.network.localizedDescription)
    }

    @MainActor
    func testLoadCurrentOfferingSetsMissingOfferingMessageWhenNil() async {
        let client = MockPurchasesClient()
        client.currentOfferingResult = .success(nil)
        let manager = RevenueCatManager(purchasesClient: client)

        await manager.loadCurrentOffering()

        XCTAssertEqual(manager.lastErrorMessage, "No active offering is configured in RevenueCat.")
    }

    @MainActor
    func testPackageLookupFindsPackageByIdentifier() async {
        let client = MockPurchasesClient()
        client.currentOfferingResult = .success(makeOffering())
        let manager = RevenueCatManager(purchasesClient: client)

        await manager.loadCurrentOffering()

        XCTAssertEqual(manager.package(named: "monthly")?.identifier, "monthly")
        XCTAssertEqual(manager.monthlyPackage?.identifier, "monthly")
        XCTAssertEqual(manager.yearlyPackage?.identifier, "yearly")
        XCTAssertNil(manager.lifetimePackage)
    }

    @MainActor
    func testPurchaseSuccessSetsCustomerInfoAndReturnsEntitlementStatus() async {
        let client = MockPurchasesClient()
        client.purchaseResult = .success(
            RevenueCatPurchaseResult(
                customerInfo: makeCustomerInfo(hasMochiPro: true),
                userCancelled: false
            )
        )
        let manager = RevenueCatManager(purchasesClient: client)
        let package = makePackage(identifier: "monthly", type: .monthly)

        let purchased = await manager.purchase(package: package)

        XCTAssertTrue(purchased)
        XCTAssertTrue(manager.hasMochiPro)
        XCTAssertFalse(manager.isLoading)
        XCTAssertEqual(client.purchaseCallCount, 1)
    }

    @MainActor
    func testPurchaseCancelledReturnsFalseWithoutSettingError() async {
        let client = MockPurchasesClient()
        client.purchaseResult = .success(
            RevenueCatPurchaseResult(
                customerInfo: makeCustomerInfo(hasMochiPro: false),
                userCancelled: true
            )
        )
        let manager = RevenueCatManager(purchasesClient: client)
        let package = makePackage(identifier: "monthly", type: .monthly)

        let purchased = await manager.purchase(package: package)

        XCTAssertFalse(purchased)
        XCTAssertNil(manager.lastErrorMessage)
        XCTAssertFalse(manager.isLoading)
    }

    @MainActor
    func testPurchaseFailureSetsErrorMessage() async {
        let client = MockPurchasesClient()
        client.purchaseResult = .failure(MockError.purchaseFailed)
        let manager = RevenueCatManager(purchasesClient: client)
        let package = makePackage(identifier: "monthly", type: .monthly)

        let purchased = await manager.purchase(package: package)

        XCTAssertFalse(purchased)
        XCTAssertEqual(manager.lastErrorMessage, MockError.purchaseFailed.localizedDescription)
        XCTAssertFalse(manager.isLoading)
    }

    @MainActor
    func testPurchaseCancelledErrorCodeDoesNotSetMessage() async {
        let cancelledError = NSError(
            domain: "RevenueCat",
            code: ErrorCode.purchaseCancelledError.rawValue,
            userInfo: [NSLocalizedDescriptionKey: "Cancelled"]
        )
        let client = MockPurchasesClient()
        client.purchaseResult = .failure(cancelledError)
        let manager = RevenueCatManager(purchasesClient: client)
        let package = makePackage(identifier: "monthly", type: .monthly)

        let purchased = await manager.purchase(package: package)

        XCTAssertFalse(purchased)
        XCTAssertNil(manager.lastErrorMessage)
    }

    @MainActor
    func testRestorePurchasesUpdatesCustomerInfo() async {
        let client = MockPurchasesClient()
        client.restoreResult = .success(makeCustomerInfo(hasMochiPro: true))
        let manager = RevenueCatManager(purchasesClient: client)

        await manager.restorePurchases()

        XCTAssertTrue(manager.hasMochiPro)
        XCTAssertFalse(manager.isLoading)
    }

    @MainActor
    func testRestorePurchasesFailureSetsErrorMessage() async {
        let client = MockPurchasesClient()
        client.restoreResult = .failure(MockError.restoreFailed)
        let manager = RevenueCatManager(purchasesClient: client)

        await manager.restorePurchases()

        XCTAssertEqual(manager.lastErrorMessage, MockError.restoreFailed.localizedDescription)
        XCTAssertFalse(manager.isLoading)
    }

    @MainActor
    private func assertEventually(
        timeout: TimeInterval = 1.0,
        pollIntervalNanos: UInt64 = 20_000_000,
        _ condition: @escaping @MainActor () -> Bool
    ) async {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() {
                return
            }
            try? await Task.sleep(nanoseconds: pollIntervalNanos)
        }
        XCTFail("Condition was not satisfied before timeout")
    }

    @MainActor
    private func makeOffering() -> Offering {
        let monthly = makePackage(identifier: "monthly", type: .monthly)
        let yearly = makePackage(identifier: "yearly", type: .annual)

        return Offering(
            identifier: "main",
            serverDescription: "Main Offering",
            metadata: [:],
            availablePackages: [monthly, yearly],
            webCheckoutUrl: nil
        )
    }

    @MainActor
    private func makePackage(identifier: String, type: PackageType) -> Package {
        let product = TestStoreProduct(
            localizedTitle: "Mochi Pro",
            price: 4.99,
            currencyCode: "USD",
            localizedPriceString: "$4.99",
            productIdentifier: "com.noahlin.mochi.\(identifier)",
            productType: .autoRenewableSubscription,
            localizedDescription: "Subscription",
            subscriptionGroupIdentifier: "mochi.pro",
            subscriptionPeriod: .init(value: 1, unit: .month),
            locale: Locale(identifier: "en_US")
        ).toStoreProduct()

        return Package(
            identifier: identifier,
            packageType: type,
            storeProduct: product,
            offeringIdentifier: "main",
            webCheckoutUrl: nil
        )
    }

    @MainActor
    private func makeCustomerInfo(hasMochiPro: Bool) -> CustomerInfo {
        let entitlements: [String: EntitlementInfo]
        if hasMochiPro {
            entitlements = [
                RevenueCatManager.mochiProEntitlementID: EntitlementInfo(
                    identifier: RevenueCatManager.mochiProEntitlementID,
                    isActive: true,
                    willRenew: true,
                    periodType: .normal,
                    latestPurchaseDate: Date(),
                    originalPurchaseDate: Date(),
                    expirationDate: Date().addingTimeInterval(86_400),
                    store: .appStore,
                    productIdentifier: "com.noahlin.mochi.monthly",
                    isSandbox: true,
                    ownershipType: .purchased
                )
            ]
        } else {
            entitlements = [:]
        }

        let entitlementInfos = EntitlementInfos(entitlements: entitlements)
        return CustomerInfo(
            entitlements: entitlementInfos,
            requestDate: Date(),
            firstSeen: Date(),
            originalAppUserId: "test-user"
        )
    }
}

private final class MockPurchasesClient: PurchasesClient {
    var isConfiguredValue = false
    var setLogLevelCallCount = 0
    var configureCallCount = 0
    var lastConfiguredAPIKey: String?
    var customerInfoCallCount = 0
    var currentOfferingCallCount = 0
    var purchaseCallCount = 0
    var restoreCallCount = 0

    var customerInfoResult: Result<CustomerInfo, Error> = .failure(MockError.unconfigured)
    var currentOfferingResult: Result<Offering?, Error> = .success(nil)
    var purchaseResult: Result<RevenueCatPurchaseResult, Error> = .failure(MockError.unconfigured)
    var restoreResult: Result<CustomerInfo, Error> = .failure(MockError.unconfigured)

    private let stream: AsyncStream<CustomerInfo>
    private let continuation: AsyncStream<CustomerInfo>.Continuation

    init() {
        var streamContinuation: AsyncStream<CustomerInfo>.Continuation?
        stream = AsyncStream { continuation in
            streamContinuation = continuation
        }
        continuation = streamContinuation!
    }

    var isConfigured: Bool {
        isConfiguredValue
    }

    var customerInfoStream: AsyncStream<CustomerInfo> {
        stream
    }

    func emitCustomerInfo(_ info: CustomerInfo) {
        continuation.yield(info)
    }

    func setLogLevel(_: LogLevel) {
        setLogLevelCallCount += 1
    }

    func configure(withAPIKey apiKey: String) {
        configureCallCount += 1
        lastConfiguredAPIKey = apiKey
        isConfiguredValue = true
    }

    func customerInfo() async throws -> CustomerInfo {
        customerInfoCallCount += 1
        return try customerInfoResult.get()
    }

    func currentOffering() async throws -> Offering? {
        currentOfferingCallCount += 1
        return try currentOfferingResult.get()
    }

    func purchase(package _: Package) async throws -> RevenueCatPurchaseResult {
        purchaseCallCount += 1
        return try purchaseResult.get()
    }

    func restorePurchases() async throws -> CustomerInfo {
        restoreCallCount += 1
        return try restoreResult.get()
    }
}

private enum MockError: LocalizedError {
    case network
    case purchaseFailed
    case restoreFailed
    case unconfigured

    var errorDescription: String? {
        switch self {
        case .network:
            return "Network request failed"
        case .purchaseFailed:
            return "Purchase failed"
        case .restoreFailed:
            return "Restore failed"
        case .unconfigured:
            return "Mock not configured"
        }
    }
}
