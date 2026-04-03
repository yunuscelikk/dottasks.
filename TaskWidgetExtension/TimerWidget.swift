import WidgetKit
import SwiftUI
import AppIntents

struct TimerEntry: TimelineEntry {
    let date: Date
    let totalSeconds: Int
    let remainingSeconds: Int
    let isRunning: Bool
    let linkedTaskTitle: String?
    let startTime: Date?
    let hasAccess: Bool
}

struct TimerProvider: TimelineProvider {
    func placeholder(in context: Context) -> TimerEntry {
        TimerEntry(date: Date(), totalSeconds: 25 * 60, remainingSeconds: 25 * 60, isRunning: false, linkedTaskTitle: "Sample Task", startTime: nil, hasAccess: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (TimerEntry) -> ()) {
        let entry = TimerEntry(date: Date(), totalSeconds: 25 * 60, remainingSeconds: 25 * 60, isRunning: false, linkedTaskTitle: nil, startTime: nil, hasAccess: true)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TimerEntry>) -> ()) {
        let hasAccess = WidgetDataManager.shared.hasAccess
        
        if !hasAccess {
            let entry = TimerEntry(
                date: Date(),
                totalSeconds: 25 * 60,
                remainingSeconds: 25 * 60,
                isRunning: false,
                linkedTaskTitle: nil,
                startTime: nil,
                hasAccess: false
            )
            let timeline = Timeline(entries: [entry], policy: .atEnd)
            completion(timeline)
            return
        }

        let manager = WidgetDataManager.shared
        let isRunning = manager.isRunning
        let total = manager.totalSeconds
        var remaining = manager.remainingSeconds
        let startTime = manager.startTime
        
        if isRunning, let start = startTime {
            let elapsed = Int(Date().timeIntervalSince(start))
            remaining = max(0, remaining - elapsed)
        }
        
        let entry = TimerEntry(
            date: Date(),
            totalSeconds: total,
            remainingSeconds: remaining,
            isRunning: isRunning,
            linkedTaskTitle: manager.linkedTaskTitle,
            startTime: startTime,
            hasAccess: true
        )
        
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: isRunning ? .after(nextUpdate) : .atEnd)
        completion(timeline)
    }
}

struct TimerWidgetView : View {
    var entry: TimerProvider.Entry
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
        ZStack {
            VStack(spacing: family == .systemMedium ? 4 : 2) {
                // Time Display
                if entry.isRunning {
                    let targetDate = Date().addingTimeInterval(TimeInterval(entry.remainingSeconds))
                    Text(targetDate, style: .timer)
                        .font(.system(size: family == .systemMedium ? 64 : 42, weight: .medium, ).monospacedDigit())
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                } else {
                    Text(timeString(entry.remainingSeconds))
                        .font(.system(size: family == .systemMedium ? 64 : 42, weight: .medium, ).monospacedDigit())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                }

                // Subtitle / Task Title
                Text(entry.linkedTaskTitle?.uppercased() ?? "FOCUS")
                    .font(.system(size: 10, weight: .bold, ))
                    .foregroundStyle(.secondary)
                    .tracking(2)
            }
            
            // Minimal Play/Pause Button in corner
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(intent: ToggleTimerIntent()) {
                        Image(systemName: entry.isRunning ? "pause.fill" : "play.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.black)
                            .frame(width: 24, height: 24)
                            .background(.white.opacity(0.8))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
        }
    }

    private var unlockView: some View {
        VStack(spacing: 8) {
            Image(systemName: "lock.fill")
                .font(.title2)
                .foregroundStyle(.white)
            Text("TAP TO UNLOCK")
                .font(.system(.caption).bold())
                .foregroundStyle(.white)
            Text("Premium required")
                .font(.system(size: 8))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func timeString(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let seconds = seconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct TimerWidget: Widget {
    let kind: String = "TimerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TimerProvider()) { entry in
            TimerWidgetView(entry: entry)
        }
        .configurationDisplayName("Timer")
        .description("Focus timer for tasks.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
