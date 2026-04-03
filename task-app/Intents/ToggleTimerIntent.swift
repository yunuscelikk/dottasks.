import AppIntents
import WidgetKit

struct ToggleTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Timer"
    static var description = IntentDescription("Starts or pauses the Pomodoro timer.")

    func perform() async throws -> some IntentResult {
        let manager = WidgetDataManager.shared
        if manager.isRunning {
            manager.pauseTimer()
        } else {
            manager.startTimer()
        }
        return .result()
    }
}
