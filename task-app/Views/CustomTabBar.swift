import SwiftUI

enum AppTab: Int, CaseIterable {
    case tasks, upcoming, timer, settings

    var icon: String {
        switch self {
        case .tasks: "checklist"
        case .upcoming: "calendar"
        case .timer: "timer"
        case .settings: "gearshape"
        }
    }

    var selectedIcon: String {
        switch self {
        case .tasks: "checklist"
        case .upcoming: "calendar"
        case .timer: "timer"
        case .settings: "gearshape.fill"
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        HStack(spacing: 6) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                tabButton(tab)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.horizontal, 40)
        .padding(.bottom, 8)
    }

    private func tabButton(_ tab: AppTab) -> some View {
        let isSelected = selectedTab == tab
        return Button {
            withAnimation(.snappy(duration: 0.25)) {
                selectedTab = tab
            }
        } label: {
            Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(isSelected ? Color.primary.opacity(0.1) : .clear)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .foregroundStyle(isSelected ? .primary : .tertiary)
                .accessibilityLabel(tabLabel(tab))
                .accessibilityAddTraits(isSelected ? .isSelected : [])
        }
        .buttonStyle(.plain)
    }

    private func tabLabel(_ tab: AppTab) -> String {
        switch tab {
        case .tasks: "Tasks"
        case .upcoming: "Upcoming"
        case .timer: "Timer"
        case .settings: "Settings"
        }
    }
}

struct SelectionTabBar: View {
    @Bindable var viewModel: TaskViewModel

    var body: some View {
        HStack(spacing: 0) {
            actionButton(icon: "checkmark.circle", color: .green) {
                viewModel.completeSelected()
            }
            actionButton(icon: "xmark.circle", color: .orange) {
                viewModel.cancelSelected()
            }
            actionButton(icon: "trash", color: .red) {
                viewModel.deleteSelected()
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        .padding(.horizontal, 40)
        .padding(.bottom, 8)
    }

    private func actionButton(icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title3)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .foregroundColor(viewModel.selectedIDs.isEmpty ? .secondary : color)
        }
        .disabled(viewModel.selectedIDs.isEmpty)
        .buttonStyle(.plain)
    }
}
