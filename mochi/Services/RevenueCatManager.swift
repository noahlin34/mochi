import Foundation
import Combine
import RevenueCat

@MainActor
final class RevenueCatManager: NSObject, ObservableObject {
    static let apiKey = "test_rHwJLSfrEHQnBvUKLpiIclbLhrS"
    static let mochiProEntitlementID = "Mochi Pro"

    @Published private(set) var customerInfo: CustomerInfo?
    @Published private(set) var currentOffering: Offering?
    @Published private(set) var isLoading: Bool = false
    @Published var lastErrorMessage: String?

    private var started = false
    private var customerInfoTask: Task<Void, Never>?

    var hasMochiPro: Bool {
        customerInfo?.entitlements.active[Self.mochiProEntitlementID] != nil
    }

    var monthlyPackage: Package? { package(named: "monthly") }
    var yearlyPackage: Package? { package(named: "yearly") }
    var lifetimePackage: Package? { package(named: "lifetime") }

    deinit {
        customerInfoTask?.cancel()
    }

    static func configureSDKIfNeeded() {
        #if DEBUG
        Purchases.logLevel = .debug
        #endif

        if !Purchases.isConfigured {
            Purchases.configure(withAPIKey: Self.apiKey)
        }
    }

    func start() {
        guard !started else { return }
        started = true

        Self.configureSDKIfNeeded()
        Purchases.shared.delegate = self

        customerInfoTask = Task { [weak self] in
            guard let self else { return }
            await self.refreshCustomerInfo()
            await self.loadCurrentOffering()

            for await info in Purchases.shared.customerInfoStream {
                guard !Task.isCancelled else { return }
                self.customerInfo = info
            }
        }
    }

    func refreshCustomerInfo() async {
        do {
            customerInfo = try await Purchases.shared.customerInfo()
        } catch {
            handle(error, fallback: "Unable to refresh subscription status.")
        }
    }

    func loadCurrentOffering() async {
        do {
            let offerings = try await Purchases.shared.offerings()
            currentOffering = offerings.current
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
            let result = try await Purchases.shared.purchase(package: package)
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
            customerInfo = try await Purchases.shared.restorePurchases()
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

extension RevenueCatManager: PurchasesDelegate {
    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            self.customerInfo = customerInfo
        }
    }
}
