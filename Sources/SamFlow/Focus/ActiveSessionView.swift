import SamFlowKit
import SwiftUI

/// Step two: the session is running. The goal stays on screen the whole time —
/// that is the entire point of the app.
struct ActiveSessionView: View {
    let controller: SessionController

    @State private var urgentPulse = false

    private var isPaused: Bool {
        if case .paused = controller.phase { return true }
        return false
    }

    private var isUrgent: Bool {
        !isPaused && controller.remaining <= Token.Ring.urgentThreshold
    }

    var body: some View {
        VStack(spacing: Token.Space.loose) {
            Text(controller.phase.session?.goal ?? "")
                .font(Token.Font.goal)
                .multilineTextAlignment(.center)
                .lineLimit(3)

            ZStack {
                CountdownRing(progress: controller.progress, isPaused: isPaused, isUrgent: isUrgent)

                VStack(spacing: 4) {
                    Text(controller.remaining.clockString)
                        .font(Token.Font.countdown)
                        .foregroundStyle(isPaused ? Color.secondary : (isUrgent ? Color.flowUrgent : Color.primary))
                        .contentTransition(.numericText(countsDown: true))

                    if isPaused {
                        Label("Paused", systemImage: "pause.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(width: Token.Ring.diameter, height: Token.Ring.diameter)
            .scaleEffect(isUrgent && urgentPulse ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.9), value: urgentPulse)
            .onChange(of: isUrgent, initial: true) { _, urgent in
                urgentPulse = false
                guard urgent else { return }
                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                    urgentPulse = true
                }
            }

            VStack(spacing: Token.Space.snug) {
                HStack(spacing: Token.Space.snug) {
                    Button(isPaused ? "Resume" : "Pause") {
                        try? isPaused ? controller.resume() : controller.pause()
                    }
                    .buttonStyle(.bordered)
                    .tint(.flowAccent)

                    Button("Goal reached") {
                        _ = try? controller.finish(.achieved)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.flowSuccess)
                    .keyboardShortcut(.defaultAction)
                }
                .controlSize(.large)

                Button("Give up") {
                    _ = try? controller.finish(.abandoned)
                }
                .buttonStyle(.plain)
                .font(.callout)
                .foregroundStyle(.secondary)
            }
        }
        .padding(Token.Space.loose)
    }
}
