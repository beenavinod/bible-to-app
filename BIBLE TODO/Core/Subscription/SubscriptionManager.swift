import Combine
import Foundation
import RevenueCat
import StoreKit
import SwiftUI
import WidgetKit

/// Auto-renewable subscription product identifiers — must match App Store Connect and RevenueCat products.
enum PremiumProductID: String, CaseIterable {
    case monthly = "abvy.1.subscription.monthly"
    case annual = "abvy.1.subscription.yearly"
}

@MainActor
final class SubscriptionManager: NSObject, ObservableObject, PurchasesDelegate {
    /// Shown after **Restore purchases** completes (success with no entitlement vs premium unlocked).
    enum RestoreFeedback: Equatable {
        case premiumUnlocked
        case noActiveSubscription

        var isPositive: Bool {
            if case .premiumUnlocked = self { return true }
            return false
        }

        var userMessage: String {
            switch self {
            case .premiumUnlocked:
                return "Premium restored."
            case .noActiveSubscription:
                return "No active subscription for this Apple ID. Use the account that purchased Premium, or subscribe below."
            }
        }
    }

    @Published private(set) var isPremium: Bool = false
    /// Populated only for non-RevenueCat / StoreKit-only flows. When `usesRevenueCat` is true, use `storeProduct(for:)`.
    @Published private(set) var products: [Product] = []
    /// RevenueCat `StoreProduct` per store identifier (Test Store + App Store) — avoids requiring `sk2Product`.
    @Published private(set) var revenueCatStoreProductsByProductID: [String: StoreProduct] = [:]
    @Published private(set) var isLoadingProducts = false
    @Published private(set) var isRestoringPurchases = false
    @Published private(set) var lastPurchaseError: String?
    @Published private(set) var restoreFeedback: RestoreFeedback?
    @Published var isPresentingPaywall = false

    weak var appState: AppState?

    private var revenueCatIdentityObserver: AnyCancellable?

    /// RevenueCat `Package` lookup for the current offering (used when purchasing through RevenueCat).
    private var packagesByProductID: [String: Package] = [:]

    /// When `true`, skips RevenueCat networking so SwiftUI previews can render the paywall using
    /// `PremiumPriceFallback` instead of live products.
    private let usesPreviewCatalog: Bool

    private var usesRevenueCat: Bool {
        RevenueCatConfig.isConfigured && !usesPreviewCatalog
    }

    init(usesPreviewCatalog: Bool = false) {
        if !usesPreviewCatalog {
            RevenueCatConfig.configurePurchasesIfNeeded()
        }
        self.usesPreviewCatalog = usesPreviewCatalog
        super.init()
        Task { @MainActor in
            guard !usesPreviewCatalog else { return }
            await refreshEntitlements()
            await loadProducts()
        }
    }

    /// Subscription manager for `#Preview` / `AppStatePreviewRoot` — no RevenueCat networking.
    static func forSwiftUIPreviews() -> SubscriptionManager {
        SubscriptionManager(usesPreviewCatalog: true)
    }

    func configure(appState: AppState) {
        self.appState = appState
        appState.subscriptionManagerForWidgets = self
        if usesRevenueCat {
            Purchases.shared.delegate = self
            revenueCatIdentityObserver = NotificationCenter.default
                .publisher(for: .bibleTodoRevenueCatIdentityChanged)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    guard let self else { return }
                    Task { await self.refreshEntitlements() }
                }
        }
    }

    func presentPaywall() {
        restoreFeedback = nil
        isPresentingPaywall = true
    }

    func dismissPaywall() {
        isPresentingPaywall = false
        lastPurchaseError = nil
        restoreFeedback = nil
    }

    func product(for id: PremiumProductID) -> Product? {
        products.first { $0.id == id.rawValue }
    }

    func storeProduct(for id: PremiumProductID) -> StoreProduct? {
        revenueCatStoreProductsByProductID[id.rawValue]
    }

    func package(for id: PremiumProductID) -> Package? {
        packagesByProductID[id.rawValue]
    }

    /// `true` when the paywall has enough catalog data to show prices (RevenueCat: package per plan; otherwise StoreKit products).
    var isPaywallCatalogReady: Bool {
        if usesPreviewCatalog { return true }
        if usesRevenueCat {
            return PremiumProductID.allCases.allSatisfy { packagesByProductID[$0.rawValue] != nil }
        }
        return !products.isEmpty
    }

    func loadProducts() async {
        if usesPreviewCatalog {
            lastPurchaseError = nil
            return
        }
        guard usesRevenueCat else {
            isLoadingProducts = false
            packagesByProductID = [:]
            revenueCatStoreProductsByProductID = [:]
            products = []
            lastPurchaseError =
                "RevenueCat is not configured. Add REVENUECAT_API_KEY_DEBUG / REVENUECAT_API_KEY_PRODUCTION to Secrets.xcconfig and configure a current offering with \(PremiumProductID.monthly.rawValue) and \(PremiumProductID.annual.rawValue)."
            return
        }
        await loadProductsRevenueCat()
    }

    private func loadProductsRevenueCat() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        do {
            let offerings = try await Purchases.shared.offerings()
            guard let current = offerings.current else {
                lastPurchaseError =
                    "No subscription offering from RevenueCat. In the dashboard create a current offering (e.g. “default”) with packages for \(PremiumProductID.monthly.rawValue) and \(PremiumProductID.annual.rawValue)."
                packagesByProductID = [:]
                revenueCatStoreProductsByProductID = [:]
                products = []
                debugLogRevenueCatOfferings(
                    offerings: offerings,
                    current: nil,
                    map: [:],
                    resolvedStoreProductIDs: [],
                    userError: lastPurchaseError
                )
                return
            }
            var map: [String: Package] = [:]
            for package in current.availablePackages {
                map[package.storeProduct.productIdentifier] = package
            }
            packagesByProductID = map
            revenueCatStoreProductsByProductID = Dictionary(
                uniqueKeysWithValues: PremiumProductID.allCases.compactMap { id in
                    guard let pkg = map[id.rawValue] else { return nil }
                    return (id.rawValue, pkg.storeProduct)
                }
            )
            products = []

            let allPlansPresent = PremiumProductID.allCases.allSatisfy { map[$0.rawValue] != nil }
            if !allPlansPresent {
                lastPurchaseError =
                    "RevenueCat offering has no packages for your product IDs. Link products \(PremiumProductID.monthly.rawValue) and \(PremiumProductID.annual.rawValue) to the current offering."
            } else {
                lastPurchaseError = nil
            }
            debugLogRevenueCatOfferings(
                offerings: offerings,
                current: current,
                map: map,
                resolvedStoreProductIDs: PremiumProductID.allCases.compactMap { map[$0.rawValue]?.storeProduct.productIdentifier },
                userError: lastPurchaseError
            )
        } catch {
            #if DEBUG
            print("SubscriptionManager[RC] offerings fetch threw: \(error)")
            let ns = error as NSError
            print("SubscriptionManager[RC] NSError domain=\(ns.domain) code=\(ns.code) userInfo=\(ns.userInfo)")
            #endif
            lastPurchaseError = error.localizedDescription
            packagesByProductID = [:]
            revenueCatStoreProductsByProductID = [:]
            products = []
        }
    }

    /// Filter Xcode console with `SubscriptionManager[RC]` (Debug builds only).
    private func debugLogRevenueCatOfferings(
        offerings: Offerings,
        current: Offering?,
        map: [String: Package],
        resolvedStoreProductIDs: [String],
        userError: String?
    ) {
        #if DEBUG
        let bundle = Bundle.main.bundleIdentifier ?? "?"
        let keyLen = RevenueCatConfig.activePublicSDKKey?.count ?? 0
        print("— SubscriptionManager[RC] offerings diagnostics —")
        print("SubscriptionManager[RC] bundleID=\(bundle)")
        print("SubscriptionManager[RC] RevenueCatConfig.isConfigured=\(RevenueCatConfig.isConfigured) apiKeyCharCount=\(keyLen) (full key never logged)")
        print("SubscriptionManager[RC] appExpectsProductIDs=\(PremiumProductID.allCases.map(\.rawValue))")
        let offeringIds = offerings.all.keys.sorted()
        print("SubscriptionManager[RC] offerings.all count=\(offeringIds.count) identifiers=\(offeringIds)")
        if let cur = current {
            print("SubscriptionManager[RC] current.identifier=\(cur.identifier)")
            print("SubscriptionManager[RC] current.availablePackages.count=\(cur.availablePackages.count)")
            for (idx, pkg) in cur.availablePackages.enumerated() {
                let sp = pkg.storeProduct
                print(
                    "SubscriptionManager[RC]   pkg[\(idx)] packageIdentifier=\(pkg.identifier) packageType=\(String(describing: pkg.packageType)) storeProductID=\(sp.productIdentifier) localizedTitle=\(sp.localizedTitle) localizedPrice=\(sp.localizedPriceString)"
                )
            }
        } else {
            print("SubscriptionManager[RC] offerings.current is nil (set a Default offering in RevenueCat)")
        }
        print("SubscriptionManager[RC] mapKeysFromCurrentPackages=\(map.keys.sorted())")
        for pid in PremiumProductID.allCases {
            let pkg = map[pid.rawValue]
            let sp = pkg?.storeProduct
            print(
                "SubscriptionManager[RC] match \(pid.rawValue): hasPackage=\(pkg != nil) storeProduct=\(sp != nil) localizedPrice=\(sp?.localizedPriceString ?? "—")"
            )
        }
        print("SubscriptionManager[RC] paywallStoreProductIDs=\(resolvedStoreProductIDs)")
        if let userError, !userError.isEmpty {
            print("SubscriptionManager[RC] userVisibleError=\(userError)")
        }
        print("— end SubscriptionManager[RC] —")
        #endif
    }

    /// Loads products if needed, then starts purchase — one tap from the paywall.
    func ensureLoadedThenPurchase(selected: PremiumProductID) async {
        lastPurchaseError = nil
        restoreFeedback = nil
        if usesRevenueCat {
            if package(for: selected) == nil {
                await loadProducts()
            }
            guard let pkg = package(for: selected) else { return }
            await purchaseRevenueCat(package: pkg)
        } else {
            if product(for: selected) == nil {
                await loadProducts()
            }
            guard let product = product(for: selected) else { return }
            await purchase(product)
        }
    }

    func refreshEntitlements() async {
        if usesPreviewCatalog { return }
        guard usesRevenueCat else {
            applyPremiumState(false)
            return
        }
        let premium = await premiumFromRevenueCatCustomerInfo()
        applyPremiumState(premium)
    }

    private func premiumFromRevenueCatCustomerInfo() async -> Bool {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            return customerInfo.entitlements[RevenueCatConfig.premiumEntitlementID]?.isActive == true
        } catch {
            return false
        }
    }

    private func applyPremiumState(_ premium: Bool) {
        isPremium = premium
        if !premium {
            appState?.applyFreeTierRestrictionsIfNeeded()
        }
        WidgetDataStore.writePremiumUnlocked(premium)
        appState?.resyncHomeWidgetVerseIfPossible()
        WidgetCenter.shared.reloadAllTimelines()
    }

    func purchase(_ product: Product) async {
        if usesPreviewCatalog { return }
        lastPurchaseError = nil
        restoreFeedback = nil
        guard usesRevenueCat else {
            lastPurchaseError = "RevenueCat is not configured. Add your public SDK key to Secrets.xcconfig."
            return
        }
        guard let pkg = packagesByProductID[product.id] else {
            lastPurchaseError = "Could not resolve package for \(product.id). Reload the paywall and try again."
            return
        }
        await purchaseRevenueCat(package: pkg)
    }

    private func purchaseRevenueCat(package: Package) async {
        do {
            let result = try await Purchases.shared.purchase(package: package)
            if result.userCancelled {
                #if DEBUG
                print("SubscriptionManager: RevenueCat purchase userCancelled")
                #endif
                return
            }
            restoreFeedback = nil
            let customerInfo = result.customerInfo
            let premium = customerInfo.entitlements[RevenueCatConfig.premiumEntitlementID]?.isActive == true
            applyPremiumState(premium)
            if isPremium { dismissPaywall() }
        } catch {
            lastPurchaseError = error.localizedDescription
        }
    }

    func restorePurchases() async {
        lastPurchaseError = nil
        restoreFeedback = nil
        if usesPreviewCatalog { return }
        guard usesRevenueCat else {
            lastPurchaseError = "RevenueCat is not configured. Add your public SDK key to Secrets.xcconfig."
            return
        }
        isRestoringPurchases = true
        defer { isRestoringPurchases = false }
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            applyRevenueCatCustomerInfo(customerInfo)
            if isPremium {
                restoreFeedback = .premiumUnlocked
                dismissPaywall()
            } else {
                restoreFeedback = .noActiveSubscription
            }
        } catch {
            lastPurchaseError = error.localizedDescription
        }
    }

    // MARK: - PurchasesDelegate

    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            self.applyRevenueCatCustomerInfo(customerInfo)
        }
    }

    private func applyRevenueCatCustomerInfo(_ customerInfo: CustomerInfo) {
        guard usesRevenueCat else { return }
        let premium = customerInfo.entitlements[RevenueCatConfig.premiumEntitlementID]?.isActive == true
        applyPremiumState(premium)
    }
}
