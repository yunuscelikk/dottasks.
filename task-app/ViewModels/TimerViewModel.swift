import SwiftUI
import Combine
import UserNotifications

enum TimerState {
    case idle, running, paused
}

@Observable
final class TimerViewModel {
    var totalSeconds: Int = 25 * 60
    var remainingSeconds: Int = 25 * 60
    var state: TimerState = .idle
    var linkedTask: TaskItem?

    /// Tracks the remaining time when the current run segment started.
    private var remainingAtRunStart: Int = 25 * 60
    /// Tracks when the current run segment started.
    private var runStartTime: Date?
    private var displayTimer: Timer?

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(totalSeconds - remainingSeconds) / Double(totalSeconds)
    }

    var timeString: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var minuteTens: Int { (remainingSeconds / 60) / 10 }
    var minuteOnes: Int { (remainingSeconds / 60) % 10 }
    var secondTens: Int { (remainingSeconds % 60) / 10 }
    var secondOnes: Int { (remainingSeconds % 60) % 10 }

    func setDuration(minutes: Int) {
        totalSeconds = minutes * 60
        remainingSeconds = totalSeconds
        state = .idle
        stopDisplayTimer()
        cancelCompletionNotification()
        updateWidgetState()
    }

    func linkTask(_ task: TaskItem?) {
        linkedTask = task
        updateWidgetState()
    }

    func start() {
        if remainingSeconds <= 0 {
            remainingSeconds = totalSeconds
        }
        state = .running
        remainingAtRunStart = remainingSeconds
        runStartTime = Date()
        startDisplayTimer()
        scheduleCompletionNotification()
        updateWidgetState()
    }

    func pause() {
        recalculateRemaining()
        state = .paused
        runStartTime = nil
        stopDisplayTimer()
        cancelCompletionNotification()
        updateWidgetState()
    }

    func reset() {
        state = .idle
        remainingSeconds = totalSeconds
        remainingAtRunStart = totalSeconds
        runStartTime = nil
        stopDisplayTimer()
        cancelCompletionNotification()
        updateWidgetState()
    }

    /// Called when the app returns to foreground to reconcile state.
    func syncFromWidget() {
        let manager = WidgetDataManager.shared
        if manager.isRunning {
            guard let start = manager.startTime else { return }
            let elapsed = Int(Date().timeIntervalSince(start))
            let remaining = max(0, manager.remainingSeconds - elapsed)
            if remaining > 0 && state != .running {
                totalSeconds = manager.totalSeconds
                remainingAtRunStart = manager.remainingSeconds
                runStartTime = start
                remainingSeconds = remaining
                state = .running
                startDisplayTimer()
                scheduleCompletionNotification()
            } else if remaining <= 0 && state == .running {
                timerCompleted()
            }
        } else if state == .running {
            // Widget paused the timer
            remainingSeconds = manager.remainingSeconds
            state = .paused
            runStartTime = nil
            stopDisplayTimer()
            cancelCompletionNotification()
        }
    }

    // MARK: - Private

    private func recalculateRemaining() {
        guard let start = runStartTime else { return }
        let elapsed = Int(Date().timeIntervalSince(start))
        remainingSeconds = max(0, remainingAtRunStart - elapsed)
    }

    private func startDisplayTimer() {
        stopDisplayTimer()
        displayTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.recalculateRemaining()
            if self.remainingSeconds <= 0 {
                self.timerCompleted()
            }
        }
    }

    private func stopDisplayTimer() {
        displayTimer?.invalidate()
        displayTimer = nil
    }

    private func timerCompleted() {
        remainingSeconds = 0
        state = .idle
        runStartTime = nil
        stopDisplayTimer()
        cancelCompletionNotification()
        playCompletionFeedback()
        updateWidgetState()
    }

    private func playCompletionFeedback() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    // MARK: - Notifications

    private func scheduleCompletionNotification() {
        cancelCompletionNotification()
        guard remainingSeconds > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Timer Complete"
        if let task = linkedTask {
            content.body = "Focus session for \"\(task.title)\" is done."
        } else {
            content.body = "Your focus session is complete."
        }
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(remainingSeconds),
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: "timer-complete",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    private func cancelCompletionNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["timer-complete"]
        )
    }

    // MARK: - Widget

    private func updateWidgetState() {
        WidgetDataManager.shared.updateTimerState(
            isRunning: state == .running,
            totalSeconds: totalSeconds,
            remainingSeconds: remainingSeconds,
            startTime: state == .running ? runStartTime : nil,
            linkedTaskTitle: linkedTask?.title
        )
    }
}
