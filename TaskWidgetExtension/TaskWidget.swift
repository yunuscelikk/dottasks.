import WidgetKit
import SwiftUI
import SwiftData
import AppIntents

struct TaskEntry: TimelineEntry {
    let date: Date
    let tasks: [TaskItem]
    let hasAccess: Bool
}

struct TaskProvider: TimelineProvider {
    func placeholder(in context: Context) -> TaskEntry {
        TaskEntry(date: Date(), tasks: [], hasAccess: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (TaskEntry) -> ()) {
        let entry = TaskEntry(date: Date(), tasks: [], hasAccess: true)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TaskEntry>) -> ()) {
        let hasAccess = WidgetDataManager.shared.hasAccess
        
        if !hasAccess {
            let entry = TaskEntry(date: Date(), tasks: [], hasAccess: false)
            let timeline = Timeline(entries: [entry], policy: .atEnd)
            completion(timeline)
            return
        }

        do {
            let config = ModelConfiguration(url: WidgetDataManager.sharedModelContainerURL)
            let container = try ModelContainer(for: Schema([TaskItem.self]), configurations: [config])
            let modelContext = ModelContext(container)
            
            let calendar = Calendar.current
            let startOfToday = calendar.startOfDay(for: Date())
            
            let descriptor = FetchDescriptor<TaskItem>(
                predicate: #Predicate<TaskItem> { task in
                    !task.isCancelled && (!task.isCompleted || task.createdAt >= startOfToday)
                }
            )
            
            let fetchedTasks = try modelContext.fetch(descriptor)
            
            let sortedTasks = fetchedTasks.sorted { (t1, t2) -> Bool in
                if t1.isCompleted != t2.isCompleted {
                    return !t1.isCompleted 
                }
                return t1.createdAt > t2.createdAt
            }
            
            let tasksToShow = Array(sortedTasks.prefix(10))
            
            let entry = TaskEntry(date: Date(), tasks: tasksToShow, hasAccess: true)
            let timeline = Timeline(entries: [entry], policy: .atEnd)
            completion(timeline)
        } catch {
            let entry = TaskEntry(date: Date(), tasks: [], hasAccess: true)
            let timeline = Timeline(entries: [entry], policy: .atEnd)
            completion(timeline)
        }
    }
}

struct TaskWidgetView : View {
    var entry: TaskProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        Group {
            if entry.hasAccess {
                accessibleView
            } else {
                unlockView
                    .widgetURL(URL(string: "taskapp://paywall"))
            }
        }
        .containerBackground(Color(red: 32/255, green: 32/255, blue: 32/255), for: .widget)
    }

    private var accessibleView: some View {
        VStack(alignment: .leading, spacing: 0) {
            if entry.tasks.isEmpty {
                Spacer()
                Text("No tasks today")
                    .font(.system(.body).bold())
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer()
            } else {
                let limit = family == .systemLarge ? 8 : (family == .systemSmall ? 3 : 4)
                VStack(alignment: .leading, spacing: family == .systemLarge ? 14 : 12) {
                    ForEach(entry.tasks.prefix(limit)) { (task: TaskItem) in
                        HStack(spacing: 14) {
                            Button(intent: ToggleTaskIntent(id: task.id)) {
                                Circle()
                                    .fill(task.isCompleted ? Color.green : Color.clear)
                                    .overlay(
                                        Circle()
                                            .stroke(task.isCompleted ? Color.green : Color.white, lineWidth: 2)
                                    )
                                    .frame(width: family == .systemSmall ? 22 : 26, height: family == .systemSmall ? 22 : 26)
                            }
                            .buttonStyle(.plain)

                            Text(task.title)
                                .font(.system(family == .systemSmall ? .body : .title3, ).bold())
                                .strikethrough(task.isCompleted)
                                .foregroundStyle(task.isCompleted ? AnyShapeStyle(.secondary) : AnyShapeStyle(Color.white))
                                .lineLimit(1)

                            Spacer()
                        }
                    }
                }

                Spacer(minLength: 0)

                if entry.tasks.count > limit {
                    Text("+ \(entry.tasks.count - limit) more")
                        .font(.system(.caption2))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var unlockView: some View {
        VStack(spacing: 8) {
            Image(systemName: "lock.fill")
                .font(.title2)
                .foregroundStyle(.white)
            Text("TAP TO UNLOCK")
                .font(.system(.caption, ).bold())
                .foregroundStyle(.white)
            Text("Premium required")
                .font(.system(size: 8))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct TaskWidget: Widget {
    let kind: String = "TaskWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TaskProvider()) { entry in
            TaskWidgetView(entry: entry)
        }
        .configurationDisplayName("Tasks")
        .description("Minimal task tracking.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
