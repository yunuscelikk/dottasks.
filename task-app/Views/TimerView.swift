import SwiftUI

struct TimerView: View {
    @Bindable var viewModel: TimerViewModel
    @State private var customMinutes: Double = 25
    @State private var isPulsing = false

    private let cardColor = Color.white.opacity(0.08)
    private let cardRadius: CGFloat = 16

    var body: some View {
        VStack(spacing: 0) {
            // Header (consistent with other screens)
            HStack(alignment: .top) {
                Text("Focus Timer")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    viewModel.reset()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 8)

            Spacer()

            // Focused task label
            if let task = viewModel.linkedTask {
                VStack(spacing: 4) {
                    Text("Focusing on")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(task.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 24)
            } else {
                // Placeholder to keep layout stable
                VStack(spacing: 4) {
                    Text(" ")
                        .font(.caption)
                    Text(" ")
                        .font(.subheadline.weight(.medium))
                }
                .padding(.bottom, 24)
            }

            // Flip clock digits
            HStack(spacing: 8) {
                // Minutes
                digitCard(viewModel.minuteTens)
                digitCard(viewModel.minuteOnes)

                // Colon
                VStack(spacing: 12) {
                    Circle()
                        .fill(.white)
                        .frame(width: 8, height: 8)
                    Circle()
                        .fill(.white)
                        .frame(width: 8, height: 8)
                }
                .padding(.horizontal, 4)
                .opacity(viewModel.state == .running ? (isPulsing ? 1.0 : 0.3) : 0.5)

                // Seconds
                digitCard(viewModel.secondTens)
                digitCard(viewModel.secondOnes)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(viewModel.remainingSeconds / 60) minutes and \(viewModel.remainingSeconds % 60) seconds remaining")
            .padding(.bottom, 40)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }

            Spacer()

            // Duration Slider (Always Visible)
            VStack(spacing: 12) {
                HStack {
                    Text("Duration")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(customMinutes)) min")
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                        .foregroundStyle(.white)
                }
                
                Slider(value: $customMinutes, in: 5...60, step: 5)
                    .tint(.white)
                    .disabled(viewModel.state != .idle)
                    .opacity(viewModel.state == .idle ? 1.0 : 0.5)
                    .onChange(of: customMinutes) { _, newValue in
                        withAnimation {
                            viewModel.setDuration(minutes: Int(newValue))
                        }
                    }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)

            // Progress bar (thin, minimal)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(.white.opacity(0.06))
                        .frame(height: 3)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(.white.opacity(0.25))
                        .frame(width: geo.size.width * viewModel.progress, height: 3)
                        .animation(.linear(duration: 1), value: viewModel.progress)
                }
            }
            .frame(height: 3)
            .padding(.horizontal, 40)
            .padding(.bottom, 40)

            // Controls
            HStack(spacing: 0) {
                // Invisible spacer to balance the unlink button
                Color.clear
                    .frame(width: 48, height: 48)
                
                Spacer()

                // Play / Pause
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    if viewModel.state == .running {
                        viewModel.pause()
                    } else {
                        viewModel.start()
                    }
                } label: {
                    Image(systemName: viewModel.state == .running ? "pause.fill" : "play.fill")
                        .font(.title2)
                        .foregroundStyle(.black)
                        .frame(width: 64, height: 64)
                        .background(.white)
                        .clipShape(Circle())
                }

                Spacer()

                // Unlink task
                Button {
                    viewModel.linkTask(nil)
                } label: {
                    Image(systemName: "xmark")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(.white.opacity(0.4))
                        .frame(width: 48, height: 48)
                }
                .opacity(viewModel.linkedTask != nil ? 1 : 0)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .onAppear {
            customMinutes = Double(viewModel.totalSeconds / 60)
        }
    }

    private func digitCard(_ digit: Int) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: cardRadius)
                .fill(cardColor)

            // Horizontal split line
            Rectangle()
                .fill(.black.opacity(0.3))
                .frame(height: 1)

            Text("\(digit)")
                .font(.system(size: 72, weight: .medium, design: .rounded).monospacedDigit())
                .foregroundStyle(.white)
        }
        .frame(width: 72, height: 100)
        .clipShape(RoundedRectangle(cornerRadius: cardRadius))
    }
}
