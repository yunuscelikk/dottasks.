import SwiftUI

struct TaskRowView: View {
    let task: TaskItem
    let isSelecting: Bool
    let isSelected: Bool
    let onToggle: () -> Void
    let onSelect: () -> Void
    let onLink: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            if isSelecting {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? .accentColor : .gray)
                    .onTapGesture(perform: onSelect)
            } else {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onToggle()
                }) {
                    ZStack {
                        Circle()
                            .stroke(circleStrokeColor, lineWidth: 1.5)
                            .frame(width: 24, height: 24)

                        if task.isCompleted {
                            Image(systemName: "checkmark")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.green)
                        } else if task.isCancelled {
                            Image(systemName: "xmark")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.red)
                        }
                    }
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.body)
                    .strikethrough(task.isCompleted || task.isCancelled)
                    .foregroundColor(titleColor)

                if let dueDate = task.dueDate {
                    Text(dueDateText(dueDate))
                        .font(.caption)
                        .foregroundColor(task.isOverdue ? .red : .secondary)
                }
            }

            Spacer()

            if task.isOverdue {
                Text("Overdue")
                    .font(.caption2)
                    .foregroundColor(.red)
            } else {
                Text("Inbox")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .onTapGesture {
            if isSelecting {
                onSelect()
            } else {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onLink()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(task.title)\(task.isCompleted ? ", completed" : "")\(task.isOverdue ? ", overdue" : "")")
        .accessibilityHint(isSelecting ? "Double tap to select" : "Double tap to focus on this task")
    }

    private var circleStrokeColor: Color {
        if task.isCancelled { return .red.opacity(0.7) }
        if task.isCompleted { return .green }
        return Color(UIColor.white).opacity(0.7)
    }

    private var titleColor: Color {
        if task.isCancelled { return .secondary }
        if task.isCompleted { return .secondary }
        return .white
    }

    private func dueDateText(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInTomorrow(date) { return "Tomorrow" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = date.hasTimeComponent ? .short : .none
        return formatter.string(from: date)
    }
}

extension Date {
    var hasTimeComponent: Bool {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: self)
        return (comps.hour ?? 0) != 0 || (comps.minute ?? 0) != 0
    }
}
