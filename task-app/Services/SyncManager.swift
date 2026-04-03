import Foundation
import SwiftData

@Observable @MainActor
final class SyncManager {
    static let shared = SyncManager()

    let container: ModelContainer

    /// Whether the user wants sync enabled. Persisted in shared UserDefaults.
    /// Changing this sets `needsRestart` — the new value takes effect on next launch.
    var isSyncEnabled: Bool {
        get { defaults?.bool(forKey: "iCloudSyncEnabled") ?? false }
        set {
            defaults?.set(newValue, forKey: "iCloudSyncEnabled")
            needsRestart = (newValue != syncActiveAtLaunch)
        }
    }

    /// True when the current toggle state differs from what the container was built with.
    var needsRestart: Bool = false

    private let defaults = UserDefaults(suiteName: WidgetDataManager.appGroupID)

    /// Tracks what the container was actually configured with at launch.
    private let syncActiveAtLaunch: Bool

    private init() {
        let wantsSync = UserDefaults(suiteName: WidgetDataManager.appGroupID)?.bool(forKey: "iCloudSyncEnabled") ?? false
        let isPremium = UserDefaults(suiteName: WidgetDataManager.appGroupID)?.bool(forKey: "isPremium") ?? false
        let active = wantsSync && isPremium
        syncActiveAtLaunch = active
        container = Self.makeContainer(syncEnabled: active)
    }

    /// Disable premium-gated features if the user lost premium (called on launch).
    func disableSyncIfNeeded() {
        let isPremium = StoreKitManager.shared.isPremium
        if !isPremium && isSyncEnabled {
            defaults?.set(false, forKey: "iCloudSyncEnabled")
        }
        if !isPremium && HydrationManager.shared.isEnabled {
            HydrationManager.shared.isEnabled = false
        }
    }

    // MARK: - Container Factory

    private static func makeContainer(syncEnabled: Bool) -> ModelContainer {
        let schema = Schema([TaskItem.self])

        if syncEnabled {
            let config = ModelConfiguration(
                schema: schema,
                url: WidgetDataManager.sharedModelContainerURL,
                cloudKitDatabase: .private("iCloud.com.celik.task-app")
            )
            do {
                return try ModelContainer(for: schema, configurations: [config])
            } catch {
                return makeContainer(syncEnabled: false)
            }
        } else {
            let config = ModelConfiguration(
                schema: schema,
                url: WidgetDataManager.sharedModelContainerURL,
                cloudKitDatabase: .none
            )
            do {
                return try ModelContainer(for: schema, configurations: [config])
            } catch {
                // Last resort: try in-memory container to avoid crash
                let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                return try! ModelContainer(for: schema, configurations: [fallback])
            }
        }
    }
}
