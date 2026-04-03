import EventKit

@Observable @MainActor
final class RemindersManager {
    static let shared = RemindersManager()

    private let store = EKEventStore()

    private(set) var authorizationStatus: EKAuthorizationStatus = .notDetermined

    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "remindersIntegrationEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "remindersIntegrationEnabled") }
    }

    var isAuthorized: Bool {
        authorizationStatus == .fullAccess
    }

    private init() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .reminder)
    }

    // MARK: - Permission

    func requestAccess() async -> Bool {
        do {
            let granted = try await store.requestFullAccessToReminders()
            authorizationStatus = EKEventStore.authorizationStatus(for: .reminder)
            return granted
        } catch {
            authorizationStatus = EKEventStore.authorizationStatus(for: .reminder)
            return false
        }
    }

    // MARK: - Create Reminder

    func addToReminders(title: String, dueDate: Date?) -> String? {
        guard isAuthorized else { return nil }

        let reminder = EKReminder(eventStore: store)
        reminder.title = title
        reminder.calendar = store.defaultCalendarForNewReminders()

        if let dueDate {
            reminder.dueDateComponents = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: dueDate
            )
        }

        do {
            try store.save(reminder, commit: true)
            return reminder.calendarItemIdentifier
        } catch {
            return nil
        }
    }

    // MARK: - Complete Reminder

    func completeReminder(id: String) {
        guard isAuthorized,
              let reminder = store.calendarItem(withIdentifier: id) as? EKReminder else { return }

        reminder.isCompleted = true
        try? store.save(reminder, commit: true)
    }

    // MARK: - Uncomplete Reminder

    func uncompleteReminder(id: String) {
        guard isAuthorized,
              let reminder = store.calendarItem(withIdentifier: id) as? EKReminder else { return }

        reminder.isCompleted = false
        try? store.save(reminder, commit: true)
    }
}
