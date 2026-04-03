# Widget Setup Instructions

To successfully add the widgets to your app, follow these manual steps in Xcode.

## 1. Create the Widget Extension Target
1. In Xcode, go to **File > New > Target...**
2. Select **Widget Extension** and click **Next**.
3. Product Name: `TaskWidgetExtension`.
4. Ensure **Include Configuration App Intent** is **unchecked** (we are using StaticConfiguration with custom AppIntents).
5. Click **Finish**.
6. When prompted to "Activate 'TaskWidgetExtension' scheme?", click **Activate**.

## 2. Configure App Groups (Required for Data Sharing)
Widgets and the main app run in separate processes. They must share an App Group to access the same SwiftData store and UserDefaults.

1. **Main App Target**:
   - Go to the **Signing & Capabilities** tab.
   - Click **+ Capability** and add **App Groups**.
   - Click the **+** button under App Groups and add: `group.com.celik.task-app`.
2. **Widget Extension Target**:
   - Go to the **Signing & Capabilities** tab.
   - Click **+ Capability** and add **App Groups**.
   - Add the same identifier: `group.com.celik.task-app`.

## 3. Add Files to Widget Extension Target
The following files need to be accessible to the `TaskWidgetExtension` target. In the Xcode File Inspector (right sidebar), ensure the **Target Membership** for these files includes both the main app and `TaskWidgetExtension`:

- `task-app/Models/TaskItem.swift`
- `task-app/Services/WidgetDataManager.swift`
- `task-app/Intents/ToggleTaskIntent.swift`
- `task-app/Intents/ToggleTimerIntent.swift`

## 4. Replace Widget Extension Code
If Xcode generated a default `TaskWidget.swift`, you can delete it or replace its contents with the code provided in the `TaskWidgetExtension/` directory.

- `TaskWidgetExtension/TaskWidget.swift`
- `TaskWidgetExtension/TimerWidget.swift`
- `TaskWidgetExtension/TaskWidgetBundle.swift`

## Troubleshooting: Xcode Launch Error (_XCWidgetKind)

If you see an error like `Please specify the widget kind in the scheme's Environment Variables using the key '_XCWidgetKind'`, it is because Xcode doesn't know which of the two widgets to launch.

1. In the top bar of Xcode, click on the **TaskWidgetExtension** scheme and select **Edit Scheme...**
2. In the left sidebar, select **Run**.
3. Go to the **Arguments** tab.
4. Under **Environment Variables**, click the **+** button.
5. Name: `_XCWidgetKind`
6. Value: `TaskWidget` (or `TimerWidget`)
7. Close and run again.

## 5. Build and Run
1. Build and run the main app on a simulator or device.
2. Go to the Home Screen, long-press, and add the **Tasks** or **Focus Timer** widget.
3. Interact with the checkboxes or play button to verify synchronization.
