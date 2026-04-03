import SwiftUI

enum DueDateOption: String, CaseIterable {
    case none = "No Date"
    case today = "Today"
    case tomorrow = "Tomorrow"
    case nextWeek = "Next Week"
    case custom = "Pick a Date"
}

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    var onAdd: (String, Date?) -> Void

    @State private var title = ""
    @State private var selectedOption: DueDateOption = .none
    @State private var customDate = Date()
    @State private var includeTime = false
    @State private var customTime = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Task title", text: $title)
                }

                Section("Due Date") {
                    ForEach(DueDateOption.allCases, id: \.self) { option in
                        Button {
                            selectedOption = option
                        } label: {
                            HStack {
                                Text(option.rawValue)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedOption == option {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }

                    if selectedOption == .custom {
                        DatePicker("Date", selection: $customDate, displayedComponents: .date)
                    }
                }

                Section {
                    Toggle("Include Time", isOn: $includeTime)
                    if includeTime {
                        DatePicker("Time", selection: $customTime, displayedComponents: .hourAndMinute)
                    }
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onAdd(title, resolvedDate)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private var resolvedDate: Date? {
        let calendar = Calendar.current
        var base: Date?

        switch selectedOption {
        case .none:
            return nil
        case .today:
            base = calendar.startOfDay(for: .now)
        case .tomorrow:
            base = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: .now))
        case .nextWeek:
            base = calendar.date(byAdding: .weekOfYear, value: 1, to: calendar.startOfDay(for: .now))
        case .custom:
            base = calendar.startOfDay(for: customDate)
        }

        guard var date = base else { return nil }

        if includeTime {
            let timeComps = calendar.dateComponents([.hour, .minute], from: customTime)
            date = calendar.date(bySettingHour: timeComps.hour ?? 0, minute: timeComps.minute ?? 0, second: 0, of: date) ?? date
        }

        return date
    }
}
