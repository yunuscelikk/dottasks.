import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var storeKit: StoreKitManager

    @State private var selectedPlan: String = "celik.taskapp.lifetime"
    @State private var isPurchasing = false
    @State private var errorMessage: String?

    private var isLifetimeSelected: Bool {
        selectedPlan == "celik.taskapp.lifetime"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // MARK: - Close Button
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 30, height: 30)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(.top, 16)
                .padding(.horizontal, 20)

                // MARK: - Hero
                VStack(spacing: 16) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 44))
                        .foregroundStyle(.yellow)
                        .padding(.top, 8)

                    VStack(spacing: 8) {
                        Text("Unlock Your\nFull Potential")
                            .font(.title.weight(.bold))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white)

                        Text("Stay focused, get more done, and build\nbetter habits — without limits.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                            .lineSpacing(2)
                    }
                }
                .padding(.bottom, 28)

                // MARK: - Benefits
                VStack(spacing: 16) {
                    benefitRow(icon: "square.grid.2x2.fill", color: .purple, text: "Home screen widgets")
                    benefitRow(icon: "icloud", color: .cyan, text: "iCloud sync across all devices")
                    benefitRow(icon: "hand.raised.fill", color: .green, text: "Private — no tracking, no ads")
                    benefitRow(icon: "heart.fill", color: .pink, text: "Support indie development")
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)

                // MARK: - Tagline
                Text("Built for productivity")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 24)

                // MARK: - Plan Selection
                VStack(spacing: 10) {
                    // Lifetime — Best Value
                    planCard(
                        id: "celik.taskapp.lifetime",
                        title: "Lifetime",
                        badge: "Best Value",
                        price: storeKit.lifetimeProduct?.displayPrice ?? "$9.99",
                        period: "",
                        detail: "Pay once, keep forever"
                    )

                    // Monthly
                    planCard(
                        id: "celik.taskapp.monthly",
                        title: "Monthly",
                        badge: nil,
                        price: storeKit.monthlyProduct?.displayPrice ?? "$1.99",
                        period: "/month",
                        detail: nil
                    )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)

                // MARK: - CTA
                VStack(spacing: 10) {
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    Button {
                        Task { await handlePurchase() }
                    } label: {
                        Group {
                            if isPurchasing {
                                ProgressView()
                                    .tint(.black)
                            } else {
                                Text(isLifetimeSelected ? "Buy Lifetime" : "Start Free Trial")
                                    .font(.headline)
                            }
                        }
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(isPurchasing)

                    Text(isLifetimeSelected
                         ? "One-time purchase. No subscription."
                         : "7-day free trial, then auto-renews. Cancel anytime.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

                // MARK: - Compliance Footer
                VStack(spacing: 12) {
                    Button {
                        Task { await storeKit.restorePurchases() }
                    } label: {
                        Text("Restore Purchases")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .underline()
                    }

                    Text(complianceText)
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.3))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding(.bottom, 30)
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
        .presentationBackground(Color.black)
    }

    // MARK: - Plan Card

    private func planCard(id: String, title: String, badge: String?, price: String, period: String, detail: String?) -> some View {
        let isSelected = selectedPlan == id

        return Button {
            selectedPlan = id
        } label: {
            HStack {
                // Radio indicator
                Circle()
                    .strokeBorder(isSelected ? Color.white : Color.white.opacity(0.3), lineWidth: isSelected ? 0 : 1.5)
                    .background(Circle().fill(isSelected ? Color.white : Color.clear))
                    .overlay {
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.black)
                        }
                    }
                    .frame(width: 22, height: 22)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.subheadline.weight(.semibold))
                        if let badge {
                            Text(badge)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Color.yellow)
                                .clipShape(Capsule())
                        }
                    }
                    if let detail {
                        Text(detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Text(price + period)
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.white : Color.white.opacity(0.12), lineWidth: isSelected ? 1.5 : 1)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(isSelected ? Color.white.opacity(0.08) : Color.clear)
                    )
            )
        }
    }

    // MARK: - Benefit Row

    private func benefitRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(color)
                .frame(width: 28)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white)
            Spacer()
        }
    }

    // MARK: - Purchase

    private func handlePurchase() async {
        isPurchasing = true
        errorMessage = nil
        do {
            if storeKit.products.isEmpty {
                await storeKit.loadProducts()
            }
            guard let product = storeKit.products.first(where: { $0.id == selectedPlan }) else {
                errorMessage = "Unable to load plans. Please check your connection and try again."
                isPurchasing = false
                return
            }
            let success = try await storeKit.purchase(product)
            if success {
                await storeKit.updatePurchasedProducts()
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isPurchasing = false
    }

    // MARK: - Compliance

    private var complianceText: String {
        let monthly = storeKit.monthlyProduct?.displayPrice ?? "$1.99"
        let lifetime = storeKit.lifetimeProduct?.displayPrice ?? "$9.99"
        return "Payment will be charged to your Apple ID account at the confirmation of purchase. Monthly subscription automatically renews unless it is canceled at least 24 hours before the end of the current period. Monthly: \(monthly)/month. Lifetime: \(lifetime) one-time purchase. Manage or cancel your subscription in your device's Settings > Apple ID > Subscriptions."
    }
}
