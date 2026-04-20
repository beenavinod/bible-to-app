import RevenueCat
import StoreKit
import SwiftUI

/// Shown in the paywall and in onboarding when products are unavailable.
enum PremiumPriceFallback {
    static let monthlyDisplay = "€4.99"
    static let annualDisplay = "€34.99"
    static let monthlyCaption = "Billed monthly"
    static let annualCaption = "Billed yearly"
}

/// Shared marketing + plans + CTAs (no `NavigationStack`).
struct PremiumPaywallCore: View {
    @EnvironmentObject private var subscription: SubscriptionManager
    @EnvironmentObject private var appState: AppState

    @Binding var selectedProductID: PremiumProductID
    /// When `true`, used inside onboarding `ScrollView` (tighter horizontal padding handled by parent).
    var compact: Bool = false
    /// Second CTA — **onboarding only**. Sheet paywall uses the navigation **Close** control instead.
    var showSkipButton: Bool = false
    var onSkip: (() -> Void)?

    private var palette: AppThemePalette { appState.palette }
    private var horizontalPadding: CGFloat { compact ? 4 : 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            header

            planPicker

            featureSection

            freeBlurb

            if let err = subscription.lastPurchaseError, !err.isEmpty {
                Text(err)
                    .font(.footnote)
                    .foregroundStyle(.red.opacity(0.9))
            }

            if let feedback = subscription.restoreFeedback {
                Text(feedback.userMessage)
                    .font(.footnote)
                    .foregroundStyle(feedback.isPositive ? palette.accent : palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            legalRow

            ctaSection
        }
        .padding(.horizontal, horizontalPadding)
        .task {
            if !subscription.isPaywallCatalogReady {
                await subscription.loadProducts()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Start living the Bible every day with personalised plans")
                .font(.title3.weight(.semibold))
                .foregroundStyle(palette.primaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var planPicker: some View {
        let rowMin: CGFloat = 152
        return HStack(alignment: .top, spacing: 12) {
            planCard(.monthly)
                .frame(maxWidth: .infinity, minHeight: rowMin, alignment: .top)
            planCard(.annual)
                .frame(maxWidth: .infinity, minHeight: rowMin, alignment: .top)
        }
    }

    private func planCard(_ id: PremiumProductID) -> some View {
        let selected = selectedProductID == id
        let storeProduct = subscription.storeProduct(for: id)
        let skProduct = subscription.product(for: id)
        return Button {
            selectedProductID = id
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .leading) {
                    if id == .annual {
                        Text("Best value")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(palette.card)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(palette.accent))
                    }
                }
                .frame(height: 22, alignment: .leading)

                Text(id == .monthly ? "Monthly" : "Yearly")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.primaryText)

                Text(displayPrice(storeProduct: storeProduct, skProduct: skProduct, id: id))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(palette.primaryText)

                Text(billingCaption(storeProduct: storeProduct, skProduct: skProduct, id: id))
                    .font(.caption)
                    .foregroundStyle(palette.secondaryText)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(palette.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(selected ? palette.accent : palette.border.opacity(0.6), lineWidth: selected ? 2.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func displayPrice(storeProduct: StoreProduct?, skProduct: Product?, id: PremiumProductID) -> String {
        if let storeProduct { return storeProduct.localizedPriceString }
        if let skProduct { return skProduct.displayPrice }
        switch id {
        case .monthly: return PremiumPriceFallback.monthlyDisplay
        case .annual: return PremiumPriceFallback.annualDisplay
        }
    }

    private func billingCaption(storeProduct: StoreProduct?, skProduct: Product?, id: PremiumProductID) -> String {
        if let storeProduct, let period = storeProduct.subscriptionPeriod {
            let caption = Self.captionForSubscriptionPeriod(unitRaw: period.unit.rawValue, value: period.value)
            if !caption.isEmpty { return caption }
        }
        if let skProduct, let sub = skProduct.subscription {
            let p = sub.subscriptionPeriod
            let caption = Self.captionForSubscriptionPeriod(unitRaw: Self.storeKitPeriodUnitRaw(p.unit), value: p.value)
            if !caption.isEmpty { return caption }
        }
        if subscription.isLoadingProducts { return "Loading price…" }
        switch id {
        case .monthly: return PremiumPriceFallback.monthlyCaption
        case .annual: return PremiumPriceFallback.annualCaption
        }
    }

    /// Aligns with `SKProductPeriodUnit` / RevenueCat `SubscriptionPeriod.Unit` raw ordering.
    private static func storeKitPeriodUnitRaw(_ unit: Product.SubscriptionPeriod.Unit) -> Int {
        switch unit {
        case .day: return 0
        case .week: return 1
        case .month: return 2
        case .year: return 3
        default: return -1
        }
    }

    /// `unitRaw`: day=0, week=1, month=2, year=3 (RevenueCat matches StoreKit here).
    private static func captionForSubscriptionPeriod(unitRaw: Int, value: Int) -> String {
        switch (unitRaw, value) {
        case (2, 1): return "Billed monthly"
        case (3, 1): return "Billed yearly"
        case (0, 1): return "Per day"
        case (1, 1): return "Per week"
        default:
            return ""
        }
    }

    private var featureSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Premium helps you")
                .font(.headline)
                .foregroundStyle(palette.primaryText)

            Group {
                featureLine("sparkles", "Personalised daily verses", "Guided actions rooted in Scripture.")
                featureLine("checkmark.circle", "Verse → daily task", "Turn every verse into something you can do.")
                featureLine("map", "Structured growth", "Follow a spiritual path that builds over time.")
                featureLine("flame.fill", "Streaks & consistency", "Stay on track with reminders and momentum.")
                featureLine("star.fill", "Deeper tasks", "Unlock richer prompts as you grow.")
            }
        }
    }

    private func featureLine(_ symbol: String, _ title: String, _ subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.body.weight(.semibold))
                .foregroundStyle(palette.accent)
                .frame(width: 28, alignment: .center)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.primaryText)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var freeBlurb: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Plus everything in the free plan")
                .font(.headline)
                .foregroundStyle(palette.primaryText)
            Text("Read today’s verse, choose solid home backgrounds, and keep Bible Life open without subscribing.")
                .font(.subheadline)
                .foregroundStyle(palette.secondaryText)
        }
    }

    private var legalRow: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                if subscription.isRestoringPurchases {
                    ProgressView()
                        .scaleEffect(0.9)
                }
                Button("Restore purchases") {
                    Task { await subscription.restorePurchases() }
                }
                .font(.footnote.weight(.semibold))
                .foregroundStyle(palette.accent)
                .disabled(subscription.isRestoringPurchases || subscription.isLoadingProducts)
            }
            .frame(maxWidth: .infinity)

            Text("Subscriptions renew automatically until cancelled in Settings. Trial eligibility is determined by Apple for your account.")
                .font(.caption2)
                .foregroundStyle(palette.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var ctaSection: some View {
        VStack(spacing: 12) {
            Button {
                Task { @MainActor in
                    await subscription.ensureLoadedThenPurchase(selected: selectedProductID)
                }
            } label: {
                Group {
                    if subscription.isLoadingProducts {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(primaryCTATitle)
                    }
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.white)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [palette.headerAccent, palette.accent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .disabled(subscription.isLoadingProducts || subscription.isRestoringPurchases)

            if showSkipButton, let onSkip {
                Button(action: onSkip) {
                    Text("Skip")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.plain)
                .foregroundStyle(palette.primaryText)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(palette.card)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(palette.border.opacity(0.85), lineWidth: 1.2)
                        )
                )
            }
        }
        .padding(.top, 4)
    }

    private var primaryCTATitle: String { "Continue" }
}

/// Marketing + plan selection; purchase flows through RevenueCat.
struct PremiumPaywallView: View {
    @EnvironmentObject private var subscription: SubscriptionManager
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var selectedProductID: PremiumProductID = .annual

    private var palette: AppThemePalette { appState.palette }

    var body: some View {
        NavigationStack {
            ScrollView {
                PremiumPaywallCore(
                    selectedProductID: $selectedProductID,
                    compact: false,
                    showSkipButton: false,
                    onSkip: nil
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
            .background(palette.canvas.ignoresSafeArea())
            .navigationTitle("Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        subscription.dismissPaywall()
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview("Premium paywall") {
    AppStatePreviewRoot { _, _ in
        PremiumPaywallView()
    }
}

#Preview("Paywall core (onboarding)") {
    AppStatePreviewRoot { appState, _ in
        ScrollView {
            PremiumPaywallCore(
                selectedProductID: .constant(.annual),
                compact: true,
                showSkipButton: true,
                onSkip: {}
            )
            .padding()
        }
        .background(appState.palette.canvas.ignoresSafeArea())
    }
}
