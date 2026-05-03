import Foundation
import RevenueCat

/// Reads RevenueCat public SDK keys from `Info.plist` (values come from xcconfig / `Secrets.xcconfig`).
///
/// - **Debug** builds use `REVENUECAT_API_KEY_DEBUG` (staging / test RevenueCat project).
/// - **Release** builds use `REVENUECAT_API_KEY_PRODUCTION` (App Store / TestFlight).
enum RevenueCatConfig {
    private static let debugKeyName = "REVENUECAT_API_KEY_DEBUG"
    private static let productionKeyName = "REVENUECAT_API_KEY_PRODUCTION"

    private static var didCallConfigure = false

    /// `true` when the active SDK key for this build is non-empty.
    static var isConfigured: Bool {
        activePublicSDKKey.map { !$0.isEmpty } ?? false
    }

    /// Public SDK key selected for the current build configuration.
    static var activePublicSDKKey: String? {
        #if DEBUG
        string(fromInfoPlist: debugKeyName)
        #else
        string(fromInfoPlist: productionKeyName)
        #endif
    }

    /// Call once at process launch before any `Purchases` usage. Safe to call multiple times (no-op after first success).
    static func configurePurchasesIfNeeded() {
        guard !didCallConfigure else { return }
        guard let key = activePublicSDKKey?.trimmingCharacters(in: .whitespacesAndNewlines), !key.isEmpty else {
            #if DEBUG
            print("RevenueCat: no API key in Info.plist. Add keys to Secrets.xcconfig.")
            #endif
            return
        }
        Purchases.configure(withAPIKey: key)
        #if DEBUG
        Purchases.logLevel = .debug
        #endif
        didCallConfigure = true
    }

    /// RevenueCat dashboard: entitlement identifier; attach both subscription products to it.
    static let premiumEntitlementID = "premium"

    private static func string(fromInfoPlist key: String) -> String? {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: key) as? String else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

extension Notification.Name {
    /// Posted after `Purchases.logIn` / `Purchases.logOut` so `SubscriptionManager` can refresh `CustomerInfo`.
    static let bibleTodoRevenueCatIdentityChanged = Notification.Name("BIBLETODORevenueCatIdentityChanged")
}
