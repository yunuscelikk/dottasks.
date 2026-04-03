# DotTasks

iOS task management and Pomodoro focus timer app built with SwiftUI, SwiftData, and WidgetKit.

## Project Structure

```
task-app/                          # Main app target
├── task_appApp.swift              # @main entry point, ModelContainer setup
├── Models/
│   └── TaskItem.swift             # SwiftData @Model (id, title, isCompleted, isCancelled, dueDate, reminderId)
├── ViewModels/
│   ├── TaskViewModel.swift        # Task CRUD, filtering, sorting, selection, reminders sync, widget updates
│   └── TimerViewModel.swift       # Pomodoro timer with background-safe time tracking, notifications
├── Views/
│   ├── ContentView.swift          # Root view: tab navigation + onboarding gate
│   ├── TaskListView.swift         # Main task list with filters, FAB, swipe actions
│   ├── TaskRowView.swift          # Individual task row (completion, due date, overdue)
│   ├── AddTaskView.swift          # Sheet for creating tasks with due date options
│   ├── TimerView.swift            # Flip-clock timer display with controls
│   ├── UpcomingView.swift         # Future tasks sorted by due date
│   ├── SettingsView.swift         # Premium, sync, reminders, hydration, data, legal
│   ├── CustomTabBar.swift         # 4-tab bar + selection action bar
│   ├── OnboardingView.swift       # 3-step onboarding, sets firstLaunchDate for trial
│   ├── PaywallView.swift          # Subscription paywall (lifetime + monthly)
│   ├── PrivacyPolicyView.swift
│   └── TermsOfServiceView.swift
├── Services/
│   ├── StoreKitManager.swift      # StoreKit 2: products, purchase, restore, isPremium state
│   ├── SyncManager.swift          # SwiftData ModelContainer factory (local vs CloudKit)
│   ├── RemindersManager.swift     # EventKit integration for Apple Reminders
│   ├── WidgetDataManager.swift    # App Group shared state (timer, progress, trial, premium)
│   └── HydrationManager.swift     # Water reminder with local notifications
├── Intents/
│   ├── ToggleTaskIntent.swift     # AppIntent: toggle task from widget
│   └── ToggleTimerIntent.swift    # AppIntent: start/pause timer from widget
└── Configuration/
    └── Products.storekit          # StoreKit config file

TaskWidgetExtension/               # Widget extension target
├── TaskWidgetExtensionBundle.swift
├── TaskWidget.swift               # Task list widget (small/medium/large)
├── TimerWidget.swift              # Timer countdown widget (small/medium)
├── ProgressWidget.swift           # Daily progress circle grid (small/medium)
└── Info.plist
```

## Key Architecture

- **Data:** SwiftData with shared store via App Group (`group.com.celik.task-app`)
- **Sync:** Optional CloudKit sync (premium only), configured at launch via `SyncManager`
- **Cross-process:** `WidgetDataManager` uses shared `UserDefaults` suite for app <-> widget communication
- **Shared constant:** `WidgetDataManager.appGroupID` — use this everywhere instead of hardcoding the string
- **Shared DB URL:** `WidgetDataManager.sharedModelContainerURL` — used by both app and widget for SwiftData
- **Monetization:** Freemium with 7-day trial. Products: `celik.taskapp.lifetime` ($9.99), `celik.taskapp.monthly` ($1.99/mo)
- **Premium features:** iCloud sync, widgets, hydration reminders

## Bundle & Identity

- **Display Name:** DotTasks
- **Bundle ID:** celik.task-app
- **App Group:** group.com.celik.task-app
- **CloudKit Container:** iCloud.com.celik.task-app
- **Team ID:** 6GRF5PZBQ2
- **Deployment Target:** iOS 26.0
- **Category:** Productivity

## Important Patterns

- All singletons (`StoreKitManager`, `SyncManager`, `RemindersManager`, `HydrationManager`) are `@MainActor`
- `WidgetDataManager` is NOT `@MainActor` (accessed from widget extension process)
- `SyncManager.container` is created once at launch; toggling sync requires app restart
- Timer uses `runStartTime` + elapsed calculation (not decrement) to survive backgrounding
- Timer schedules a `UNNotificationRequest` on start, cancels on pause/reset
- Widget premium gating uses `WidgetDataManager.hasAccess` (checks trial date + isPremium)
- `disableSyncIfNeeded()` also disables hydration when premium expires

## Coding Conventions

- SwiftUI + @Observable (no ObservableObject/Combine)
- Dark theme: black backgrounds, white text, `.secondary` for subtitles
- Card-based settings UI using private `CardView` component
- Custom tab bar (not native TabView)
- Haptic feedback on interactive elements (completion toggle, timer controls, task link)
- No third-party dependencies

## Things to Watch Out For

- Changing `iCloudSyncEnabled` toggle requires app restart (ModelContainer is immutable)
- Widget intents create their own `ModelContainer` — can't share the app's container
- `Products.storekit` must be set as the StoreKit Configuration in the active scheme for testing
- Privacy key `NSRemindersFullAccessUsageDescription` is required for iOS 17+ reminders access
- `SyncManager` falls back to in-memory store if local DB creation fails (avoids crash)
- The `#if DEBUG` block in SettingsView has a trial expiry button — never ships in Release
