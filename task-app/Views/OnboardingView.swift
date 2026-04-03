import SwiftUI

struct OnboardingView: View {
    @State private var currentStep = 0
    var onComplete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .fill(.white.opacity(0.06))
                    .frame(width: 140, height: 140)

                Image(systemName: stepIcon)
                    .font(.system(size: 56))
                    .foregroundStyle(.white)
                    .contentTransition(.symbolEffect(.replace))
            }
            .padding(.bottom, 40)

            VStack(spacing: 12) {
                Text(stepTitle)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(stepSubtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 40)
            }

            Spacer()

            VStack(spacing: 16) {
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        if currentStep < 2 {
                            currentStep += 1
                        } else {
                            if WidgetDataManager.shared.firstLaunchDate == nil {
                                WidgetDataManager.shared.firstLaunchDate = Date()
                            }
                            onComplete()
                        }
                    }
                } label: {
                    Text(currentStep < 2 ? "Continue" : "Get Started")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(.white)
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
                        Capsule()
                            .fill(index == currentStep ? .white : .white.opacity(0.2))
                            .frame(width: index == currentStep ? 24 : 8, height: 8)
                            .animation(.easeInOut(duration: 0.3), value: currentStep)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 50)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }

    private var stepIcon: String {
        switch currentStep {
        case 0: "checklist"
        case 1: "timer"
        default: "sparkles"
        }
    }

    private var stepTitle: String {
        switch currentStep {
        case 0: "Your tasks,\nyour way"
        case 1: "Stay in the zone"
        default: "Simple by design"
        }
    }

    private var stepSubtitle: String {
        switch currentStep {
        case 0: "A clean, distraction-free space to organize what matters most to you."
        case 1: "Use the focus timer to work in deep sessions. Link a task and get to work."
        default: "No clutter, no noise. Just you and your tasks. That's it."
        }
    }
}
