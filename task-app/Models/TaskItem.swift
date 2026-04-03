import Foundation
import SwiftData

@Model
final class TaskItem {
    var id: UUID = UUID()
    var title: String = ""
    var isCompleted: Bool = false
    var isCancelled: Bool = false
    var createdAt: Date = Date()
    var dueDate: Date?
    var reminderId: String?

    init(title: String, dueDate: Date? = nil) {
        self.id = UUID()
        self.title = title
        self.isCompleted = false
        self.isCancelled = false
        self.createdAt = Date()
        self.dueDate = dueDate
    }

    var isOverdue: Bool {
        guard let dueDate, !isCompleted, !isCancelled else { return false }
        return dueDate < Date.now
    }
}
