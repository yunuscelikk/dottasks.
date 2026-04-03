import SwiftUI
import StoreKit
import WidgetKit
import EventKit

struct SettingsView: View {
    @Bindable var timerViewModel: TimerViewModel
    var taskViewModel: TaskViewModel?
    @Bindable var storeKit: StoreKitManager

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @State private var syncManager = SyncManager.shared
    @State private var remindersManager = RemindersManager.shared
    @State private var hydration = HydrationManager.shared
    @State private var showDeleteAllAlert = false
    @State private var showResetAlert = false
    @State private var showClearCompletedAlert = false
    @State private var showClearCancelledAlert = false
    @State private var showPrivacyPolicy = false
    @State private var showTermsOfService = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Settings")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.top, 16)

                subscriptionCard
                integrationsCard
                hydrationCard
                statsCard
                dataCard
                helpCard
                legalCard
                aboutCard
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .background(Color.black)
        .task {
            await storeKit.loadProducts()
            await storeKit.updatePurchasedProducts()
        }
        .alert("Delete All Tasks", isPresented: $showDeleteAllAlert) {
            Button("Delete", role: .destructive) {
                taskViewModel?.deleteAllTasks()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all your tasks. This cannot be undone.")
        }
        .alert("Clear Completed", isPresented: $showClearCompletedAlert) {
            Button("Clear", role: .destructive) {
                taskViewModel?.deleteCompleted()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all completed tasks.")
        }
        .alert("Clear Cancelled", isPresented: $showClearCancelledAlert) {
            Button("Clear", role: .destructive) {
                taskViewModel?.deleteCancelled()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all cancelled tasks.")
        }
        .alert("Reset App", isPresented: $showResetAlert) {
            Button("Reset", role: .destructive) {
                taskViewModel?.deleteAllTasks()
                timerViewModel.reset()
                timerViewModel.setDuration(minutes: 25)
                timerViewModel.linkTask(nil)
                hasCompletedOnboarding = false
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will delete all tasks, reset the timer, and show onboarding again.")
        }
    }

    // MARK: - Subscription

    @State private var showPaywall = false

    private var subscriptionCard: some View {
        VStack(spacing: 0) {
            if storeKit.isPremium {
                VStack(spacing: 12) {
                    Image(systemName: "crown.fill")
                        .font(.largeTitle)
                        .foregroundColor(.yellow)

                    Text("You're Premium")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.black)

                    Text(storeKit.isLifetime ? "Lifetime access" : "\(storeKit.activePlanName) plan active")
                        .font(.subheadline)
                        .foregroundStyle(.black.opacity(0.6))

                    if !storeKit.isLifetime {
                        Button {
                            Task {
                                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
                                try? await AppStore.showManageSubscriptions(in: windowScene)
                            }
                        } label: {
                            Text("Manage Subscription")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.black.opacity(0.7))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.black.opacity(0.08))
                                .clipShape(Capsule())
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(24)
            } else {
                VStack(spacing: 14) {
                    Image(systemName: "sparkles")
                        .font(.largeTitle)
                        .foregroundColor(.black.opacity(0.8))

                    Text("Upgrade to Premium")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.black)

                    Text("Unlock home screen widgets, iCloud sync, and support indie development.")
                        .font(.subheadline)
                        .foregroundStyle(.black.opacity(0.5))
                        .multilineTextAlignment(.center)

                    Button {
                        showPaywall = true
                    } label: {
                        Text("See Plans")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.black)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.top, 4)
                }
                .padding(24)
            }

            Button {
                Task { await storeKit.restorePurchases() }
            } label: {
                Group {
                    switch storeKit.restoreStatus {
                    case .idle:
                        Text("Restore Purchases")
                    case .restoring:
                        HStack(spacing: 6) {
                            ProgressView()
                                .tint(.black.opacity(0.35))
                            Text("Restoring...")
                        }
                    case .success:
                        Label("Restored!", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    case .failed:
                        Label("No purchases found", systemImage: "xmark.circle.fill")
                            .foregroundStyle(.red.opacity(0.7))
                    }
                }
                .font(.caption)
                .foregroundStyle(.black.opacity(0.35))
            }
            .disabled(storeKit.restoreStatus == .restoring)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView(storeKit: storeKit)
        }
    }

    // MARK: - Integrations

    private var integrationsCard: some View {
        CardView(title: "Sync & Reminders") {
            VStack(spacing: 16) {
                // iCloud Sync
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "icloud")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .frame(width: 20)

                        Toggle(isOn: Binding(
                            get: { syncManager.isSyncEnabled },
                            set: { syncManager.isSyncEnabled = $0 }
                        )) {
                            HStack(spacing: 6) {
                                Text("iCloud Sync")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.yellow)
                            }
                        }
                        .tint(.blue)
                        .disabled(!storeKit.isPremium)
                    }

                    if syncManager.needsRestart && storeKit.isPremium {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.trianglehead.2.counterclockwise")
                                .font(.caption2)
                            Text("Restart the app to apply changes")
                                .font(.caption)
                        }
                        .foregroundStyle(.orange)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 32)
                    } else if syncManager.isSyncEnabled && storeKit.isPremium {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.icloud")
                                .font(.caption2)
                            Text("Your tasks sync across all your devices")
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 32)
                    }
                }

                // Apple Reminders
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "list.bullet")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .frame(width: 20)

                        Toggle(isOn: Binding(
                            get: { remindersManager.isEnabled },
                            set: { newValue in
                                if newValue {
                                    Task {
                                        let granted = await remindersManager.requestAccess()
                                        remindersManager.isEnabled = granted
                                    }
                                } else {
                                    remindersManager.isEnabled = false
                                }
                            }
                        )) {
                            Text("Apple Reminders")
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                        .tint(.blue)
                    }

                    if remindersManager.isEnabled && remindersManager.isAuthorized {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle")
                                .font(.caption2)
                            Text("Swipe right on a task to add it to Reminders")
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 32)
                    } else if remindersManager.authorizationStatus == .denied {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.caption2)
                            Text("Permission denied — enable in Settings")
                                .font(.caption)
                        }
                        .foregroundStyle(.orange)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 32)
                    }
                }
            }
        }
    }

    // MARK: - Hydration

    private var hydrationCard: some View {
        CardView(title: "Hydration") {
            VStack(spacing: 14) {
                // Toggle
                HStack(spacing: 12) {
                    Image(systemName: "drop.fill")
                        .font(.subheadline)
                        .foregroundColor(.cyan)
                        .frame(width: 20)

                    Toggle(isOn: Binding(
                        get: { hydration.isEnabled },
                        set: { newValue in
                            if newValue {
                                Task {
                                    let granted = await hydration.requestNotificationPermission()
                                    hydration.isEnabled = granted
                                }
                            } else {
                                hydration.isEnabled = false
                            }
                        }
                    )) {
                        HStack(spacing: 6) {
                            Text("Water Reminder")
                                .font(.subheadline)
                                .foregroundColor(.white)
                            Image(systemName: "crown.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.yellow)
                        }
                    }
                    .tint(.cyan)
                    .disabled(!storeKit.isPremium)
                }

                if hydration.isEnabled && storeKit.isPremium {
                    // Progress + Drink button
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(hydration.currentIntake) of \(hydration.dailyGoal) glasses")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)

                            if hydration.goalReached {
                                Text("Goal reached!")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            }
                        }

                        Spacer()

                        Button {
                            withAnimation(.easeOut(duration: 0.2)) {
                                hydration.drinkWater()
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                    .font(.caption.weight(.bold))
                                Text("Drink")
                                    .font(.caption.weight(.semibold))
                            }
                            .foregroundStyle(.black)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(.cyan)
                            .clipShape(Capsule())
                        }
                    }

                    // Goal selector
                    HStack {
                        Text("Daily goal")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Picker("Goal", selection: Binding(
                            get: { hydration.dailyGoal },
                            set: { hydration.dailyGoal = $0 }
                        )) {
                            ForEach([4, 6, 8, 10, 12], id: \.self) { n in
                                Text("\(n) glasses").tag(n)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.white)
                    }

                    // Interval selector
                    HStack {
                        Text("Remind every")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Picker("Interval", selection: Binding(
                            get: { hydration.reminderInterval },
                            set: { hydration.reminderInterval = $0 }
                        )) {
                            ForEach([30, 45, 60, 90, 120], id: \.self) { m in
                                Text("\(m) min").tag(m)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.white)
                    }
                }
            }
        }
    }

    // MARK: - Stats

    @ViewBuilder
    private var statsCard: some View {
        if let vm = taskViewModel {
            CardView(title: "Overview") {
                VStack(spacing: 0) {
                    let stats: [(String, Int, Color)] = [
                        ("Active", vm.allTasks.filter { !$0.isCompleted && !$0.isCancelled }.count, .white),
                        ("Completed", vm.allTasks.filter { $0.isCompleted }.count, .green),
                        ("Cancelled", vm.allTasks.filter { $0.isCancelled }.count, .orange),
                        ("Overdue", vm.allTasks.filter { $0.isOverdue }.count, .red)
                    ]

                    HStack(spacing: 0) {
                        ForEach(stats, id: \.0) { stat in
                            VStack(spacing: 4) {
                                Text("\(stat.1)")
                                    .font(.title2.weight(.bold))
                                    .foregroundStyle(stat.2)
                                Text(stat.0)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }

                }
            }
        }
    }

    // MARK: - Data

    private var dataCard: some View {
        CardView(title: "Data") {
            VStack(spacing: 2) {
                settingsButton(icon: "checkmark.circle", title: "Clear Completed", color: .green) {
                    showClearCompletedAlert = true
                }
                settingsButton(icon: "xmark.circle", title: "Clear Cancelled", color: .orange) {
                    showClearCancelledAlert = true
                }
                settingsButton(icon: "trash", title: "Delete All Tasks", color: .red) {
                    showDeleteAllAlert = true
                }
                settingsButton(icon: "arrow.counterclockwise", title: "Reset App", color: .red) {
                    showResetAlert = true
                }
                
                #if DEBUG
                settingsButton(icon: "clock.badge.exclamationmark", title: "DEBUG: Expire Trial", color: .purple) {
                    let tenDaysAgo = Date().addingTimeInterval(-10 * 24 * 60 * 60)
                    let defaults = UserDefaults(suiteName: WidgetDataManager.appGroupID)
                    defaults?.set(tenDaysAgo, forKey: "firstLaunchDate")
                    defaults?.set(false, forKey: "isPremium")
                    WidgetCenter.shared.reloadAllTimelines()
                }
                #endif
            }
        }
    }

    private func settingsButton(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundColor(color)
                    .frame(width: 20)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 10)
        }
    }

    // MARK: - Help & Feedback

    private var helpCard: some View {
        CardView(title: "Help & Feedback") {
            VStack(spacing: 2) {
                settingsButton(icon: "star", title: "Rate App", color: .yellow) {
                    guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
                    AppStore.requestReview(in: scene)
                }
                settingsButton(icon: "envelope", title: "Send Feedback", color: .blue) {
                    if let url = URL(string: "mailto:yunuscelik@example.com?subject=Task%20App%20Feedback") {
                        UIApplication.shared.open(url)
                    }
                }
                settingsButton(icon: "questionmark.circle", title: "Help & FAQ", color: .white) {
                    if let url = URL(string: "https://example.com/help") {
                        UIApplication.shared.open(url)
                    }
                }
            }
        }
    }

    // MARK: - Legal

    private var legalCard: some View {
        CardView(title: "Legal") {
            VStack(spacing: 2) {
                settingsButton(icon: "hand.raised", title: "Privacy Policy", color: .white) {
                    showPrivacyPolicy = true
                }
                settingsButton(icon: "doc.text", title: "Terms of Service", color: .white) {
                    showTermsOfService = true
                }
            }
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showTermsOfService) {
            TermsOfServiceView()
        }
    }

    // MARK: - About

    private var aboutCard: some View {
        CardView(title: "About") {
            HStack {
                Text("Version")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    .font(.subheadline)
                    .foregroundStyle(.white)
            }
        }
    }
}

// MARK: - Card Component

private struct CardView<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .tracking(0.5)

            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
