import Foundation
import WidgetKit

final class WidgetDataManager {
    static let shared = WidgetDataManager()
    static let appGroupID = "group.com.celik.task-app"

    private let defaults: UserDefaults?

    private init() {
        defaults = UserDefaults(suiteName: Self.appGroupID)
    }
    
    // MARK: - Timer State
    
    var isRunning: Bool {
        get { defaults?.bool(forKey: "isRunning") ?? false }
        set { defaults?.set(newValue, forKey: "isRunning") }
    }
    
    var totalSeconds: Int {
        get { defaults?.integer(forKey: "totalSeconds") ?? (25 * 60) }
        set { defaults?.set(newValue, forKey: "totalSeconds") }
    }
    
    var remainingSeconds: Int {
        get { defaults?.integer(forKey: "remainingSeconds") ?? (25 * 60) }
        set { defaults?.set(newValue, forKey: "remainingSeconds") }
    }
    
    var startTime: Date? {
        get { defaults?.object(forKey: "startTime") as? Date }
        set { defaults?.set(newValue, forKey: "startTime") }
    }
    
    var linkedTaskTitle: String? {
        get { defaults?.string(forKey: "linkedTaskTitle") }
        set { defaults?.set(newValue, forKey: "linkedTaskTitle") }
    }
    
    // MARK: - Trial & Premium Access
    
    var firstLaunchDate: Date? {
        get { defaults?.object(forKey: "firstLaunchDate") as? Date }
        set { defaults?.set(newValue, forKey: "firstLaunchDate") }
    }
    
    var hasAccess: Bool {
        // App Group defaults üzerinden oku
        let isPremium = defaults?.bool(forKey: "isPremium") ?? false
        if isPremium { return true }
        
        guard let firstLaunch = firstLaunchDate else {
            return true // Henüz tarih set edilmemişse erişim ver (ilk kullanım)
        }
        
        let sevenDays: TimeInterval = 7 * 24 * 60 * 60
        let timePassed = Date().timeIntervalSince(firstLaunch)
        
        return timePassed < sevenDays
    }
    
    func updateTimerState(isRunning: Bool, totalSeconds: Int, remainingSeconds: Int, startTime: Date?, linkedTaskTitle: String?) {
        self.isRunning = isRunning
        self.totalSeconds = totalSeconds
        self.remainingSeconds = remainingSeconds
        self.startTime = startTime
        self.linkedTaskTitle = linkedTaskTitle
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func startTimer() {
        self.isRunning = true
        self.startTime = Date()
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func pauseTimer() {
        if let start = self.startTime {
            let elapsed = Int(Date().timeIntervalSince(start))
            self.remainingSeconds = max(0, self.remainingSeconds - elapsed)
        }
        self.isRunning = false
        self.startTime = nil
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    // MARK: - Progress State

    var progressTotal: Int {
        get { defaults?.integer(forKey: "progressTotal") ?? 0 }
        set { defaults?.set(newValue, forKey: "progressTotal") }
    }

    var progressCompleted: Int {
        get { defaults?.integer(forKey: "progressCompleted") ?? 0 }
        set { defaults?.set(newValue, forKey: "progressCompleted") }
    }

    // MARK: - SwiftData Shared URL
    
    nonisolated static var sharedModelContainerURL: URL {
        let fileManager = FileManager.default
        guard let groupURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            return fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("default.store")
        }
        return groupURL.appendingPathComponent("default.store")
    }
}
