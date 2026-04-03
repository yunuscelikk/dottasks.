import SwiftUI
import SwiftData
import WidgetKit

enum TaskFilter: String, CaseIterable {
    case all = "All"
    case active = "Active"
    case completed = "Completed"
    case cancelled = "Cancelled"
    case overdue = "Overdue"
}

enum TaskSort: String, CaseIterable {
    case newestFirst = "Newest First"
    case oldestFirst = "Oldest First"
    case alphabetical = "A → Z"
    case dueDate = "Due Date"
}

@Observable
final class TaskViewModel {
    private var modelContext: ModelContext

    var allTasks: [TaskItem] = []
    var filter: TaskFilter = .all
    var sort: TaskSort = .newestFirst
    var selectedIDs: Set<UUID> = []
    var isSelecting: Bool = false

    private var todayTasks: [TaskItem] {
        let calendar = Calendar.current
        return allTasks.filter { task in
            guard let due = task.dueDate else { return true }
            return calendar.isDateInToday(due) || due < Date.now
        }
    }

    var tasks: [TaskItem] {
        let filtered: [TaskItem]
        switch filter {
        case .all:
            filtered = todayTasks
        case .active:
            filtered = todayTasks.filter { !$0.isCompleted && !$0.isCancelled }
        case .completed:
            filtered = todayTasks.filter { $0.isCompleted }
        case .cancelled:
            filtered = todayTasks.filter { $0.isCancelled }
        case .overdue:
            filtered = todayTasks.filter { $0.isOverdue }
        }

        switch sort {
        case .newestFirst:
            return filtered.sorted { $0.createdAt > $1.createdAt }
        case .oldestFirst:
            return filtered.sorted { $0.createdAt < $1.createdAt }
        case .alphabetical:
            return filtered.sorted { $0.title.localizedCompare($1.title) == .orderedAscending }
        case .dueDate:
            return filtered.sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
        }
    }

    var upcomingTasks: [TaskItem] {
        allTasks
            .filter { !$0.isCompleted && !$0.isCancelled && $0.dueDate != nil && $0.dueDate! > Date.now }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchTasks()
    }

    func fetchTasks() {
        let descriptor = FetchDescriptor<TaskItem>()
        allTasks = (try? modelContext.fetch(descriptor)) ?? []
    }

    func addTask(title: String, dueDate: Date? = nil) {
        let task = TaskItem(title: title, dueDate: dueDate)
        modelContext.insert(task)
        save()
    }

    func toggleCompletion(_ task: TaskItem) {
        task.isCompleted.toggle()
        if task.isCompleted { task.isCancelled = false }
        syncReminderCompletion(task)
        save()
    }

    func toggleCancelled(_ task: TaskItem) {
        task.isCancelled.toggle()
        if task.isCancelled { task.isCompleted = false }
        save()
    }

    func deleteTask(_ task: TaskItem) {
        modelContext.delete(task)
        save()
    }

    func deleteCompleted() {
        for task in allTasks where task.isCompleted {
            modelContext.delete(task)
        }
        save()
    }

    func deleteCancelled() {
        for task in allTasks where task.isCancelled {
            modelContext.delete(task)
        }
        save()
    }

    func deleteAllTasks() {
        for task in allTasks {
            modelContext.delete(task)
        }
        save()
    }

    // MARK: - Selection

    func toggleSelection(_ task: TaskItem) {
        if selectedIDs.contains(task.id) {
            selectedIDs.remove(task.id)
        } else {
            selectedIDs.insert(task.id)
        }
    }

    func selectAll() {
        selectedIDs = Set(tasks.map(\.id))
    }

    func deselectAll() {
        selectedIDs.removeAll()
    }

    func completeSelected() {
        for task in allTasks where selectedIDs.contains(task.id) {
            task.isCompleted = true
            task.isCancelled = false
        }
        exitSelection()
        save()
    }

    func cancelSelected() {
        for task in allTasks where selectedIDs.contains(task.id) {
            task.isCancelled = true
            task.isCompleted = false
        }
        exitSelection()
        save()
    }

    func deleteSelected() {
        for task in allTasks where selectedIDs.contains(task.id) {
            modelContext.delete(task)
        }
        exitSelection()
        save()
    }

    func exitSelection() {
        isSelecting = false
        selectedIDs.removeAll()
    }

    // MARK: - Reminders

    func addToReminders(_ task: TaskItem) {
        let reminders = RemindersManager.shared
        guard reminders.isEnabled, reminders.isAuthorized else { return }
        guard task.reminderId == nil else { return }

        if let id = reminders.addToReminders(title: task.title, dueDate: task.dueDate) {
            task.reminderId = id
            save()
        }
    }

    private func syncReminderCompletion(_ task: TaskItem) {
        let reminders = RemindersManager.shared
        guard reminders.isEnabled, let id = task.reminderId else { return }

        if task.isCompleted {
            reminders.completeReminder(id: id)
        } else {
            reminders.uncompleteReminder(id: id)
        }
    }

    private func save() {
        try? modelContext.save()
        fetchTasks()
        updateProgressWidget()
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func updateProgressWidget() {
        let calendar = Calendar.current
        let todayAll = allTasks.filter { task in
            guard !task.isCancelled else { return false }
            // Include tasks created today OR due today
            if calendar.isDateInToday(task.createdAt) { return true }
            if let due = task.dueDate, calendar.isDateInToday(due) { return true }
            return false
        }
        let manager = WidgetDataManager.shared
        manager.progressTotal = todayAll.count
        manager.progressCompleted = todayAll.filter { $0.isCompleted }.count
    }
}
