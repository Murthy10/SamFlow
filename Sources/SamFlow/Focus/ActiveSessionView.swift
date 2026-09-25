import SamFlowKit
import SwiftUI

/// Step two: the session is running. The goal stays on screen the whole time —
/// that is the entire point of the app.
struct ActiveSessionView: View {
    let controller: SessionController

    private var isPaused: Bool {
        if case .paused = controller.phase { return true }
        return false
    }

    var body: some View {
        VStack(spacing: Token.Space.base) {
            Text(controller.phase.session?.goal ?? "")
                .font(Token.Font.goal)
                .multilineTextAlignment(.center)
                .lineLimit(3)

            Text(controller.remaining.clockString)
                .font(Token.Font.countdown)
                .foregroundStyle(isPaused ? AnyShapeStyle(.secondary) : AnyShapeStyle(.primary))
                .contentTransition(.numericText(countsDown: true))

            ProgressView(value: controller.progress)
                .frame(maxWidth: 260)

            HStack(spacing: Token.Space.snug) {
                Button(isPaused ? "Resume" : "Pause") {
                    try? isPaused ? controller.resume() : controller.pause()
                }
                Button("Give up") {
                    _ = try? controller.finish(.abandoned)
                }
                Button("Goal reached") {
                    _ = try? controller.finish(.achieved)
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(Token.Space.loose)
    }
}
