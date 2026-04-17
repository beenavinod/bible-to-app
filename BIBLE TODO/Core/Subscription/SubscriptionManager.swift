import Combine
import Foundation
import StoreKit
import SwiftUI
import WidgetKit

/// Auto-renewable subscription product identifiers — must match App Store Connect and `PremiumSubscriptions.storekit`.
/// **Local testing:** `BIBLE TODO.xcodeproj/xcshareddata/PremiumSubscriptions.storekit` — shared Run schemes use `../PremiumSubscriptions.storekit` (one level up from `xcschemes/`), which matches where Xcode usually writes the path.
enum PremiumProductID: String, CaseIterable {
    case monthly = "abvy.BIBLE-TODO.premium.monthly"
    case annual = "abvy.BIBLE-TODO.premium.annual"
}

@MainActor
final class SubscriptionManager: ObservableObject {
    @Published private(set) var isPremium: Bool = false
    @Published private(set) var products: [Product] = []
    @Published private(set) var isLoadingProducts = false
    @Published private(set) var lastPurchaseError: String?
    @Published var isPresentingPaywall = false

    weak var appState: AppState?

    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = Task { @MainActor in
            await listenForTransactionUpdates()
        }
        Task { @MainActor in
            await refreshEntitlements()
            await loadProducts()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    func configure(appState: AppState) {
        self.appState = appState
    }

    func presentPaywall() {
        isPresentingPaywall = true
    }

    func dismissPaywall() {
        isPresentingPaywall = false
    }

    func product(for id: PremiumProductID) -> Product? {
        products.first { $0.id == id.rawValue }
    }

    func loadProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        let ids = PremiumProductID.allCases.map(\.rawValue)
        do {
            var loaded = try await Product.products(for: ids)
            #if DEBUG
            if loaded.isEmpty {
                try await Task.sleep(nanoseconds: 450_000_000)
                loaded = try await Product.products(for: ids)
            }
            #endif
            products = loaded.sorted { lhs, rhs in
                guard
                    let li = PremiumProductID(rawValue: lhs.id),
                    let ri = PremiumProductID(rawValue: rhs.id)
                else { return lhs.id < rhs.id }
                return li.sortIndex < ri.sortIndex
            }
            if products.isEmpty {
                let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
                #if DEBUG
                let env = ProcessInfo.processInfo.environment
                let skHints = env.filter { entry in
                    let k = entry.key.lowercased()
                    return k.contains("storekit") || k.contains("xctest") || k.contains("dyld_insert")
                }
                print(
                    "SubscriptionManager: Product.products returned []. previews=\(isPreview) bundle=\(Bundle.main.bundleIdentifier ?? "?") AppStore.canMakePayments=\(AppStore.canMakePayments) storekitEnv=\(skHints)"
                )
                #endif
                if isPreview {
                    lastPurchaseError =
                        "Subscriptions are not loaded in SwiftUI previews. Run the BIBLE TODO scheme with ⌘R (StoreKit config is attached to the Run action, not to previews)."
                } else {
                    lastPurchaseError =
                        "No subscription products loaded. Run with ⌘R from Xcode. Scheme → Run → Options → StoreKit: PremiumSubscriptions.storekit (under .xcodeproj/xcshareddata/). For App Store builds you need a paid Apple Developer account for In-App Purchase; local .storekit testing does not. IDs: \(PremiumProductID.monthly.rawValue), \(PremiumProductID.annual.rawValue)."
                }
            } else {
                lastPurchaseError = nil
            }
        } catch {
            lastPurchaseError = error.localizedDescription
        }
    }

    /// Loads products if needed, then starts `purchase` — one tap from the paywall.
    func ensureLoadedThenPurchase(selected: PremiumProductID) async {
        lastPurchaseError = nil
        if product(for: selected) == nil {
            await loadProducts()
        }
        guard let product = product(for: selected) else { return }
        await purchase(product)
    }

    func refreshEntitlements() async {
        var premium = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if PremiumProductID(rawValue: transaction.productID) != nil {
                premium = true
                break
            }
        }
        let wasPremium = isPremium
        isPremium = premium
        if wasPremium, !premium {
            appState?.applyFreeTierRestrictionsIfNeeded()
        }
        WidgetDataStore.writePremiumUnlocked(premium)
        appState?.resyncHomeWidgetVerseIfPossible()
        WidgetCenter.shared.reloadAllTimelines()
    }

    func purchase(_ product: Product) async {
        lastPurchaseError = nil
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    #if DEBUG
                    print("SubscriptionManager: purchase success verified id=\(transaction.id) product=\(transaction.productID)")
                    #endif
                    await transaction.finish()
                    await refreshEntitlements()
                    if isPremium { dismissPaywall() }
                case .unverified(_, let error):
                    lastPurchaseError = error.localizedDescription
                }
            case .userCancelled:
                #if DEBUG
                print("SubscriptionManager: purchase userCancelled")
                #endif
            case .pending:
                lastPurchaseError = "Purchase is pending (for example Ask to Buy). Check again after it’s approved."
                #if DEBUG
                print("SubscriptionManager: purchase pending")
                #endif
            @unknown default:
                break
            }
        } catch {
            lastPurchaseError = error.localizedDescription
        }
    }

    func restorePurchases() async {
        lastPurchaseError = nil
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            if isPremium { dismissPaywall() }
        } catch {
            lastPurchaseError = error.localizedDescription
        }
    }

    private func listenForTransactionUpdates() async {
        for await update in Transaction.updates {
            guard case .verified(let transaction) = update else { continue }
            await transaction.finish()
            await refreshEntitlements()
        }
    }
}

private extension PremiumProductID {
    var sortIndex: Int {
        switch self {
        case .monthly: 0
        case .annual: 1
        }
    }
}
