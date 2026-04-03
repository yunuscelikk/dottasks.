import StoreKit

@Observable @MainActor
final class StoreKitManager {
    static let shared = StoreKitManager()

    private(set) var products: [Product] = []
    private(set) var isPremium: Bool = false {
        didSet {
            UserDefaults(suiteName: WidgetDataManager.appGroupID)?.set(isPremium, forKey: "isPremium")
        }
    }
    private(set) var purchasedProductIDs: Set<String> = []
    private(set) var activeProductID: String?
    var restoreStatus: RestoreStatus = .idle

    enum RestoreStatus {
        case idle, restoring, success, failed
    }

    private let productIDs: Set<String> = [
        "celik.taskapp.monthly",
        "celik.taskapp.lifetime"
    ]

    private var updateTask: Task<Void, Never>?

    static let defaultPomodoroDuration = 25

    init() {
        updateTask = Task { [weak self] in
            guard let self else { return }
            for await result in Transaction.updates {
                if let transaction = try? result.payloadValue {
                    await self.handleTransaction(transaction)
                }
            }
        }
    }


    func loadProducts() async {
        guard products.isEmpty else { return }
        do {
            products = try await Product.products(for: productIDs)
                .sorted { $0.price < $1.price }
        } catch {
            #if DEBUG
            print("Failed to load products: \(error)")
            #endif
        }
    }

    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            if let transaction = try? verification.payloadValue {
                await handleTransaction(transaction)
                await updatePurchasedProducts()
                return isPremium
            }
            return false
        case .userCancelled, .pending:
            return false
        @unknown default:
            return false
        }
    }

    func restorePurchases() async {
        restoreStatus = .restoring
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
            restoreStatus = isPremium ? .success : .failed
        } catch {
            restoreStatus = .failed
        }

        try? await Task.sleep(for: .seconds(3))
        restoreStatus = .idle
    }

    func updatePurchasedProducts() async {
        var purchasedIDs: Set<String> = []
        var activeID: String?
        for await result in Transaction.currentEntitlements {
            if let transaction = try? result.payloadValue {
                if transaction.revocationDate == nil {
                    purchasedIDs.insert(transaction.productID)
                    activeID = transaction.productID
                }
            }
        }
        purchasedProductIDs = purchasedIDs
        activeProductID = activeID
        isPremium = !purchasedIDs.isEmpty
    }

    private func handleTransaction(_ transaction: Transaction) async {
        if transaction.revocationDate == nil {
            purchasedProductIDs.insert(transaction.productID)
            activeProductID = transaction.productID
        } else {
            purchasedProductIDs.remove(transaction.productID)
            if activeProductID == transaction.productID {
                activeProductID = nil
            }
        }
        isPremium = !purchasedProductIDs.isEmpty
        await transaction.finish()
    }

    var monthlyProduct: Product? {
        products.first { $0.id == "celik.taskapp.monthly" }
    }

    var lifetimeProduct: Product? {
        products.first { $0.id == "celik.taskapp.lifetime" }
    }

    var activePlanName: String {
        switch activeProductID {
        case "celik.taskapp.monthly": return "Monthly"
        case "celik.taskapp.lifetime": return "Lifetime"
        default: return "None"
        }
    }

    var isLifetime: Bool {
        purchasedProductIDs.contains("celik.taskapp.lifetime")
    }
}
