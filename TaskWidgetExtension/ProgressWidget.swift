import WidgetKit
import SwiftUI

struct ProgressEntry: TimelineEntry {
    let date: Date
    let completed: Int
    let total: Int
    let hasAccess: Bool
}

struct ProgressProvider: TimelineProvider {
    func placeholder(in context: Context) -> ProgressEntry {
        ProgressEntry(date: Date(), completed: 5, total: 9, hasAccess: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (ProgressEntry) -> ()) {
        completion(ProgressEntry(date: Date(), completed: 5, total: 9, hasAccess: true))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ProgressEntry>) -> ()) {
        let manager = WidgetDataManager.shared
        let hasAccess = manager.hasAccess

        if !hasAccess {
            let entry = ProgressEntry(date: Date(), completed: 0, total: 0, hasAccess: false)
            let timeline = Timeline(entries: [entry], policy: .atEnd)
            completion(timeline)
            return
        }

        let entry = ProgressEntry(
            date: Date(),
            completed: manager.progressCompleted,
            total: manager.progressTotal,
            hasAccess: true
        )
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct ProgressCircleGrid: View {
    let completed: Int
    let total: Int
    let columns: Int
    let circleSize: CGFloat
    let spacing: CGFloat

    var body: some View {
        let maxCircles = columns * columns
        let displayTotal = min(total, maxCircles)
        let displayCompleted = min(completed, displayTotal)

        let grid = Array(repeating: GridItem(.fixed(circleSize), spacing: spacing), count: columns)

        LazyVGrid(columns: grid, spacing: spacing) {
            ForEach(0..<displayTotal, id: \.self) { index in
                Circle()
                    .fill(index < displayCompleted ? Color.white : Color.gray.opacity(0.3))
                    .frame(width: circleSize, height: circleSize)
            }
        }
    }
}

struct ProgressWidgetView: View {
    var entry: ProgressProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        Group {
            if entry.hasAccess {
                circleView
            } else {
                unlockView
                    .widgetURL(URL(string: "taskapp://paywall"))
            }
        }
        .containerBackground(Color(red: 32/255, green: 32/255, blue: 32/255), for: .widget)
    }

    private var circleView: some View {
        Group {
            if entry.total == 0 {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .accessibilityLabel("No tasks today")
            } else {
                switch family {
                case .systemMedium:
                    ProgressCircleGrid(
                        completed: entry.completed,
                        total: entry.total,
                        columns: 5,
                        circleSize: 20,
                        spacing: 10
                    )
                default:
                    ProgressCircleGrid(
                        completed: entry.completed,
                        total: entry.total,
                        columns: 4,
                        circleSize: 22,
                        spacing: 8
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(entry.completed) of \(entry.total) tasks completed")
    }

    private var unlockView: some View {
        VStack(spacing: 8) {
            Image(systemName: "lock.fill")
                .font(.title2)
                .foregroundStyle(.white)
            Text("TAP TO UNLOCK")
                .font(.system(.caption, design: .default).bold())
                .foregroundStyle(.white)
            Text("Premium required")
                .font(.system(size: 8))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ProgressWidget: Widget {
    let kind: String = "ProgressWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ProgressProvider()) { entry in
            ProgressWidgetView(entry: entry)
        }
        .configurationDisplayName("Progress")
        .description("Daily task progress.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
