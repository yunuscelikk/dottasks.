import Foundation
import AppIntents
import SwiftData
import WidgetKit

struct ToggleTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Task Completion"
    static var description = IntentDescription("Marks a task as completed or active.")

    @Parameter(title: "Task ID")
    var id: String

    init() { }
    init(id: UUID) { 
        self.id = id.uuidString 
    }

    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: id) else { return .result() }

        let config = ModelConfiguration(url: WidgetDataManager.sharedModelContainerURL)
        let container = try ModelContainer(for: Schema([TaskItem.self]), configurations: [config])
        let modelContext = ModelContext(container)

        let descriptor = FetchDescriptor<TaskItem>(predicate: #Predicate { $0.id == uuid })
        if let task = try modelContext.fetch(descriptor).first {
            task.isCompleted.toggle()
            if task.isCompleted {
                task.isCancelled = false
            }
            try modelContext.save()
        }

        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let allDescriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate<TaskItem> { task in
                !task.isCancelled && task.createdAt >= startOfToday
            }
        )
        let todayTasks = (try? modelContext.fetch(allDescriptor)) ?? []
        let manager = WidgetDataManager.shared
        manager.progressTotal = todayTasks.count
        manager.progressCompleted = todayTasks.filter { $0.isCompleted }.count

        WidgetCenter.shared.reloadAllTimelines()

        return .result()
    }
}
