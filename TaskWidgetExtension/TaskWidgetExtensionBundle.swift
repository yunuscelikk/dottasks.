import WidgetKit
import SwiftUI

@main
struct TaskWidgetExtensionBundle: WidgetBundle {
    var body: some Widget {
        TaskWidget()
        TimerWidget()
        ProgressWidget()
    }
}
