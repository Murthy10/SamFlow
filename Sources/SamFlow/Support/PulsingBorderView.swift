import Observation
import SwiftUI

/// Shared with `ScreenBorderController`: how far the active session has
/// progressed, and whether it's currently paused or in its final minute. A
/// separate `@Observable` object rather than reusing `SessionController`
/// directly, so the border overlay windows only redraw for the three things
/// that change how they look.
@Observable
final class BorderState {
    /// 0...1, elapsed fraction of the planned duration. Reaches 1 exactly
    /// when time runs out, at which point the border traces a full loop.
    var progress: Double = 0
    var isPaused = false
    var isUrgent = false
}

/// The fine border traced around every screen while a session is active — it
/// fills in as the session progresses and closes into a complete loop the
/// moment time is up, an ambient reminder of how much of the goal's window is
/// left that stays visible even while working in another app. Purely
/// decorative: the window that hosts this ignores every mouse event, so it
/// never gets in the way.
struct PulsingBorderView: View {
    let state: BorderState

    @State private var urgentPulse = false

    private var tint: Color {
        state.isPaused ? .secondary : (state.isUrgent ? .flowUrgent : .flowAccent)
    }

    var body: some View {
        ZStack {
            Rectangle()
                .stroke(.quaternary, lineWidth: Token.Border.lineWidth)

            Rectangle()
                .trim(from: 0, to: max(0, min(1, state.progress)))
                .stroke(
                    tint.opacity(state.isUrgent && urgentPulse ? 1 : 0.75),
                    style: StrokeStyle(lineWidth: Token.Border.lineWidth, lineCap: .round)
                )
                .animation(Token.Motion.progress, value: state.progress)
                .animation(Token.Motion.phase, value: tint)
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
        .animation(
            state.isUrgent ? .easeInOut(duration: 1.2).repeatForever(autoreverses: true) : .default,
            value: urgentPulse
        )
        .onAppear { urgentPulse = true }
    }
}
