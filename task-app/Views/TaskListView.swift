import SwiftUI

struct TaskListView: View {
    @Bindable var viewModel: TaskViewModel
    @Bindable var timerViewModel: TimerViewModel
    var onStartTimerWithTask: ((TaskItem) -> Void)?

    @State private var showingAddSheet = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            List {
                    Section {
                        header
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))

                    if viewModel.tasks.isEmpty {
                        Section {
                            emptyState
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    } else {
                        Section {
                            ForEach(viewModel.tasks) { task in
                                TaskRowView(
                                    task: task,
                                    isSelecting: viewModel.isSelecting,
                                    isSelected: viewModel.selectedIDs.contains(task.id),
                                    onToggle: { viewModel.toggleCompletion(task) },
                                    onSelect: { viewModel.toggleSelection(task) },
                                    onLink: { timerViewModel.linkTask(task) }
                                )
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        viewModel.deleteTask(task)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    Button {
                                        viewModel.toggleCancelled(task)
                                    } label: {
                                        Label(
                                            task.isCancelled ? "Restore" : "Cancel",
                                            systemImage: task.isCancelled ? "arrow.uturn.backward" : "xmark"
                                        )
                                    }
                                    .tint(.orange)
                                }
                                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                    if RemindersManager.shared.isEnabled && task.reminderId == nil {
                                        Button {
                                            viewModel.addToReminders(task)
                                        } label: {
                                            Label("Reminders", systemImage: "list.bullet")
                                        }
                                        .tint(.blue)
                                    }
                                }
                            }
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.black)

            fabButton
        }
        .background(Color.black)
        .sheet(isPresented: $showingAddSheet) {
            AddTaskView { title, dueDate in
                viewModel.addTask(title: title, dueDate: dueDate)
            }
            .presentationDetents([.medium, .large])
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if viewModel.isSelecting {
                    Button {
                        if viewModel.selectedIDs.count == viewModel.tasks.count {
                            viewModel.deselectAll()
                        } else {
                            viewModel.selectAll()
                        }
                    } label: {
                        Text(viewModel.selectedIDs.count == viewModel.tasks.count ? "Deselect All" : "Select All")
                            .font(.subheadline)
                    }

                    Spacer()

                    Text("\(viewModel.selectedIDs.count) selected")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button("Done") {
                        viewModel.exitSelection()
                    }
                    .font(.subheadline.weight(.semibold))
                } else {
                    Spacer()
                    menuButton
                }
            }
            .frame(height: 44)

            HStack(alignment: .top) {
                Text(headerTitle)
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.white)

                Spacer()

                VStack(alignment: .trailing, spacing: 0) {
                    Text(Date.now, format: .dateTime.day())
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(.white)
                    Text(Date.now, format: .dateTime.month(.abbreviated))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if viewModel.filter != .all {
                Button {
                    viewModel.filter = .all
                } label: {
                    Label(viewModel.filter.rawValue, systemImage: "xmark.circle.fill")
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Capsule())
                        .foregroundColor(.white)
                }
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 8)
    }

    private var headerTitle: String {
        switch viewModel.filter {
        case .all: return "Today"
        case .active: return "Active"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        case .overdue: return "Overdue"
        }
    }

    // MARK: - Menu

    private var menuButton: some View {
        Menu {
            Menu {
                ForEach(TaskFilter.allCases, id: \.self) { filter in
                    Button {
                        viewModel.filter = filter
                    } label: {
                        HStack {
                            Text(filter.rawValue)
                            if viewModel.filter == filter {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Label("Filter", systemImage: "line.3.horizontal.decrease")
            }

            Menu {
                ForEach(TaskSort.allCases, id: \.self) { sort in
                    Button {
                        viewModel.sort = sort
                    } label: {
                        HStack {
                            Text(sort.rawValue)
                            if viewModel.sort == sort {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Label("Sort", systemImage: "arrow.up.arrow.down")
            }

            Divider()

            Button {
                viewModel.isSelecting = true
            } label: {
                Label("Select Tasks", systemImage: "checkmark.circle")
            }

            Divider()

            Button(role: .destructive) {
                viewModel.deleteCompleted()
            } label: {
                Label("Clear Completed", systemImage: "trash")
            }

            Button(role: .destructive) {
                viewModel.deleteCancelled()
            } label: {
                Label("Clear Cancelled", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(Color.white.opacity(0.1))
                .clipShape(Circle())
        }
    }

    // MARK: - FAB

    private var fabButton: some View {
        Button {
            if viewModel.isSelecting && !viewModel.selectedIDs.isEmpty {
                if let task = viewModel.tasks.first(where: { viewModel.selectedIDs.contains($0.id) }) {
                    viewModel.exitSelection()
                    onStartTimerWithTask?(task)
                }
            } else {
                showingAddSheet = true
            }
        } label: {
            Image(systemName: viewModel.isSelecting && !viewModel.selectedIDs.isEmpty ? "timer" : "plus")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.black)
                .frame(width: 60, height: 60)
                .background(.white)
                .clipShape(Circle())
                .shadow(color: .white.opacity(0.15), radius: 8, y: 2)
        }
        .disabled(viewModel.isSelecting && viewModel.selectedIDs.isEmpty)
        .padding(.trailing, 24)
        .padding(.bottom, 24)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: emptyIcon)
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.15))

            Text(emptyTitle)
                .font(.headline)
                .foregroundStyle(.white.opacity(0.7))

            Text(emptySubtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
        .padding(.horizontal, 40)
    }

    private var emptyIcon: String {
        switch viewModel.filter {
        case .all: viewModel.allTasks.isEmpty ? "checklist" : "tray"
        case .active: "checkmark.seal"
        case .completed: "trophy"
        case .cancelled: "xmark.bin"
        case .overdue: "clock.badge.checkmark"
        }
    }

    private var emptyTitle: String {
        switch viewModel.filter {
        case .all: viewModel.allTasks.isEmpty ? "Your day starts here" : "No matching tasks"
        case .active: "All caught up"
        case .completed: "No completed tasks yet"
        case .cancelled: "No cancelled tasks"
        case .overdue: "Nothing overdue"
        }
    }

    private var emptySubtitle: String {
        switch viewModel.filter {
        case .all: viewModel.allTasks.isEmpty ? "Tap + to add your first task" : "Try changing your filter or sort"
        case .active: "Complete or add new tasks to see them here"
        case .completed: "Finished tasks will appear here"
        case .cancelled: "Cancelled tasks will appear here"
        case .overdue: "You're on track — nice work"
        }
    }
}
