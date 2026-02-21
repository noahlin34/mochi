import Combine
import Foundation
import RevenueCat

struct RevenueCatPurchaseResult {
    let customerInfo: CustomerInfo
    let userCancelled: Bool
}

protocol PurchasesClient: AnyObject {
    var isConfigured: Bool { get }
    var customerInfoStream: AsyncStream<CustomerInfo> { get }

    func setLogLevel(_ level: LogLevel)
    func configure(withAPIKey apiKey: String)
    func customerInfo() async throws -> CustomerInfo
    func currentOffering() async throws -> Offering?
    func purchase(package: Package) async throws -> RevenueCatPurchaseResult
    func restorePurchases() async throws -> CustomerInfo
}

final class LivePurchasesClient: PurchasesClient {
    var isConfigured: Bool {
        Purchases.isConfigured
    }

    var customerInfoStream: AsyncStream<CustomerInfo> {
        AsyncStream { continuation in
            let task = Task {
                for await info in Purchases.shared.customerInfoStream {
                    continuation.yield(info)
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    func setLogLevel(_ level: LogLevel) {
        Purchases.logLevel = level
    }

    func configure(withAPIKey apiKey: String) {
        Purchases.configure(withAPIKey: apiKey)
    }

    func customerInfo() async throws -> CustomerInfo {
        try await Purchases.shared.customerInfo()
    }

    func currentOffering() async throws -> Offering? {
        try await Purchases.shared.offerings().current
    }

    func purchase(package: Package) async throws -> RevenueCatPurchaseResult {
        let result = try await Purchases.shared.purchase(package: package)
        return RevenueCatPurchaseResult(
            customerInfo: result.customerInfo,
            userCancelled: result.userCancelled
        )
    }

    func restorePurchases() async throws -> CustomerInfo {
        try await Purchases.shared.restorePurchases()
    }
}

@MainActor
final class RevenueCatManager: NSObject, ObservableObject {
    static let apiKey = "appl_mqXkjELSloDKZbAQVbenpxYfSSV"
    static let mochiProEntitlementID = "Mochi Pro"

    @Published private(set) var customerInfo: CustomerInfo?
    @Published private(set) var currentOffering: Offering?
    @Published private(set) var isLoading: Bool = false
    @Published var lastErrorMessage: String?

    private let purchasesClient: PurchasesClient
    private var started = false
    private var customerInfoTask: Task<Void, Never>?

    init(purchasesClient: PurchasesClient = LivePurchasesClient()) {
        self.purchasesClient = purchasesClient
    }

    var hasMochiPro: Bool {
        customerInfo?.entitlements.active[Self.mochiProEntitlementID] != nil
    }

    var monthlyPackage: Package? { package(named: "monthly") }
    var yearlyPackage: Package? { package(named: "yearly") }
    var lifetimePackage: Package? { package(named: "lifetime") }

    deinit {
        customerInfoTask?.cancel()
    }

    static func configureSDKIfNeeded(purchasesClient: PurchasesClient = LivePurchasesClient()) {
        #if DEBUG
        purchasesClient.setLogLevel(.debug)
        #endif

        if !purchasesClient.isConfigured {
            purchasesClient.configure(withAPIKey: Self.apiKey)
        }
    }

    func start() {
        guard !started else { return }
        started = true

        Self.configureSDKIfNeeded(purchasesClient: purchasesClient)
        let stream = purchasesClient.customerInfoStream

        customerInfoTask = Task { [weak self] in
            await self?.refreshCustomerInfo()
            await self?.loadCurrentOffering()

            for await info in stream {
                guard !Task.isCancelled else { return }
                await MainActor.run { [weak self] in
                    self?.customerInfo = info
                }
            }
        }
    }

    func refreshCustomerInfo() async {
        do {
            customerInfo = try await purchasesClient.customerInfo()
        } catch {
            handle(error, fallback: "Unable to refresh subscription status.")
        }
    }

    func loadCurrentOffering() async {
        do {
            currentOffering = try await purchasesClient.currentOffering()
            if currentOffering == nil {
                lastErrorMessage = "No active offering is configured in RevenueCat."
            }
        } catch {
            handle(error, fallback: "Unable to load purchase options.")
        }
    }

    func purchase(package: Package) async -> Bool {
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await purchasesClient.purchase(package: package)
            customerInfo = result.customerInfo

            if result.userCancelled {
                return false
            }

            return result.customerInfo.entitlements.active[Self.mochiProEntitlementID] != nil
        } catch {
            handle(error, fallback: "Purchase failed. Please try again.")
            return false
        }
    }

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }

        do {
            customerInfo = try await purchasesClient.restorePurchases()
        } catch {
            handle(error, fallback: "Restore failed. Please try again.")
        }
    }

    func package(named identifier: String) -> Package? {
        currentOffering?.availablePackages.first(where: { $0.identifier == identifier })
    }

    private func handle(_ error: Error, fallback: String) {
        let nsError = error as NSError
        if let code = ErrorCode(rawValue: nsError.code), code == .purchaseCancelledError {
            return
        }
        let localizedDescription = nsError.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        lastErrorMessage = localizedDescription.isEmpty ? fallback : localizedDescription
    }
}
