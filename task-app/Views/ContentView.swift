import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var taskViewModel: TaskViewModel?
    @State private var timerViewModel = TimerViewModel()
    @State private var storeKit = StoreKitManager.shared
    @State private var selectedTab: AppTab = .tasks
    @State private var showingPaywall = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        if !hasCompletedOnboarding {
            OnboardingView {
                hasCompletedOnboarding = true
            }
        } else {
            mainContent
        }
    }

    private var mainContent: some View {
        VStack(spacing: 0) {
            Group {
                switch selectedTab {
                case .tasks:
                    if let vm = taskViewModel {
                        TaskListView(viewModel: vm, timerViewModel: timerViewModel) { task in
                            timerViewModel.linkTask(task)
                            timerViewModel.start()
                            selectedTab = .timer
                        }
                    }
                case .upcoming:
                    if let vm = taskViewModel {
                        UpcomingView(viewModel: vm, timerViewModel: timerViewModel)
                    }
                case .timer:
                    TimerView(viewModel: timerViewModel)
                        .padding(.top, 8)
                case .settings:
                    SettingsView(timerViewModel: timerViewModel, taskViewModel: taskViewModel, storeKit: storeKit)
                }
            }
            .frame(maxHeight: .infinity)

            if let vm = taskViewModel, vm.isSelecting {
                SelectionTabBar(viewModel: vm)
            } else {
                CustomTabBar(selectedTab: $selectedTab)
            }
        }
        .task {
            await storeKit.updatePurchasedProducts()
        }
        .onAppear {
            if taskViewModel == nil {
                taskViewModel = TaskViewModel(modelContext: modelContext)
            }
            HydrationManager.shared.resetIfNewDay()
        }
        .onOpenURL { url in
            if url.scheme == "taskapp" && url.host == "paywall" {
                showingPaywall = true
            }
        }
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                taskViewModel?.fetchTasks()
                timerViewModel.syncFromWidget()
            }
        }
        .fullScreenCover(isPresented: $showingPaywall) {
            PaywallView(storeKit: storeKit)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: TaskItem.self, inMemory: true)
}
