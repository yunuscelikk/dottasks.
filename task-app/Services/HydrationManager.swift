import Foundation
import UserNotifications

@Observable @MainActor
final class HydrationManager {
    static let shared = HydrationManager()

    private let defaults = UserDefaults.standard
    private let center = UNUserNotificationCenter.current()

    // MARK: - Observable State

    var isEnabled: Bool {
        didSet {
            defaults.set(isEnabled, forKey: "hydrationEnabled")
            if isEnabled {
                scheduleNotifications()
            } else {
                cancelNotifications()
            }
        }
    }

    var dailyGoal: Int {
        didSet { defaults.set(dailyGoal, forKey: "hydrationDailyGoal") }
    }

    var reminderInterval: Int {
        didSet {
            defaults.set(reminderInterval, forKey: "hydrationInterval")
            if isEnabled { scheduleNotifications() }
        }
    }

    var currentIntake: Int {
        didSet { defaults.set(currentIntake, forKey: "hydrationCurrentIntake") }
    }

    var lastDrinkDate: Date? {
        didSet { defaults.set(lastDrinkDate, forKey: "hydrationLastDrinkDate") }
    }

    var goalReached: Bool { currentIntake >= dailyGoal }

    // MARK: - Init

    private init() {
        self.isEnabled = defaults.bool(forKey: "hydrationEnabled")
        let goal = defaults.integer(forKey: "hydrationDailyGoal")
        self.dailyGoal = goal > 0 ? goal : 8
        let interval = defaults.integer(forKey: "hydrationInterval")
        self.reminderInterval = interval > 0 ? interval : 60
        self.currentIntake = defaults.integer(forKey: "hydrationCurrentIntake")
        self.lastDrinkDate = defaults.object(forKey: "hydrationLastDrinkDate") as? Date

        resetIfNewDay()
    }

    // MARK: - Actions

    func drinkWater() {
        resetIfNewDay()
        currentIntake += 1
        lastDrinkDate = Date()

        if goalReached {
            cancelNotifications()
        }
    }

    func requestNotificationPermission() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound])
        } catch {
            return false
        }
    }

    // MARK: - Daily Reset

    func resetIfNewDay() {
        guard let lastDate = lastDrinkDate else { return }
        if !Calendar.current.isDateInToday(lastDate) {
            currentIntake = 0
            if isEnabled { scheduleNotifications() }
        }
    }

    // MARK: - Notifications

    func scheduleNotifications() {
        cancelNotifications()

        guard isEnabled, !goalReached else { return }

        let intervalSeconds = TimeInterval(reminderInterval * 60)
        let count = min(10, dailyGoal - currentIntake)

        for i in 1...count {
            let content = UNMutableNotificationContent()
            content.title = "Time to hydrate"
            content.body = "You've had \(currentIntake) of \(dailyGoal) glasses today."
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: intervalSeconds * Double(i),
                repeats: false
            )

            let request = UNNotificationRequest(
                identifier: "hydration-\(i)",
                content: content,
                trigger: trigger
            )

            center.add(request)
        }
    }

    func cancelNotifications() {
        let ids = (1...10).map { "hydration-\($0)" }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }
}
