import SwiftUI
import SwiftData

@main
struct task_appApp: App {
    @State private var syncManager = SyncManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    await StoreKitManager.shared.loadProducts()
                    await StoreKitManager.shared.updatePurchasedProducts()
                    syncManager.disableSyncIfNeeded()
                }
        }
        .modelContainer(syncManager.container)
    }
}
