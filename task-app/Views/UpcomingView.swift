import SwiftUI

struct UpcomingView: View {
    @Bindable var viewModel: TaskViewModel
    @Bindable var timerViewModel: TimerViewModel

    @State private var showingAddSheet = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Spacer()
                            menuButton
                        }
                        .frame(height: 44)

                        Text("Upcoming")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))

                if viewModel.upcomingTasks.isEmpty {
                    Section {
                        VStack(spacing: 12) {
                            Image(systemName: "calendar")
                                .font(.system(size: 48))
                                .foregroundStyle(.white.opacity(0.15))

                            Text("Plan ahead")
                                .font(.headline)
                                .foregroundStyle(.white.opacity(0.7))

                            Text("Add tasks with a due date\nto see them here")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 80)
                        .padding(.horizontal, 40)
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else {
                    Section {
                        ForEach(viewModel.upcomingTasks) { task in
                            UpcomingRow(task: task, onToggle: { viewModel.toggleCompletion(task) })
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        viewModel.deleteTask(task)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    Button {
                                        viewModel.toggleCancelled(task)
                                    } label: {
                                        Label("Cancel", systemImage: "xmark")
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

    // MARK: - Menu

    private var menuButton: some View {
        Menu {
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
            showingAddSheet = true
        } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.black)
                .frame(width: 60, height: 60)
                .background(.white)
                .clipShape(Circle())
                .shadow(color: .white.opacity(0.15), radius: 8, y: 2)
        }
        .padding(.trailing, 24)
        .padding(.bottom, 24)
    }
}

private struct UpcomingRow: View {
    let task: TaskItem
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Button(action: onToggle) {
                Circle()
                    .stroke(Color.white.opacity(0.7), lineWidth: 1.5)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.body)
                    .foregroundColor(.white)

                if let dueDate = task.dueDate {
                    Text(dueDate, format: .dateTime.month(.abbreviated).day().year())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if let dueDate = task.dueDate {
                Text(relativeDay(dueDate))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    private func relativeDay(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInTomorrow(date) { return "Tomorrow" }
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: .now), to: calendar.startOfDay(for: date)).day ?? 0
        if days > 0 { return "\(days)d" }
        return ""
    }
}
