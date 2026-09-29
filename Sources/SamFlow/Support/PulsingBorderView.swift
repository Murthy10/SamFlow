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

/// The border traced around every screen while a session is active — it
/// fills in as the session progresses and closes into a complete loop the
/// moment time is up, an ambient reminder of how much of the goal's window is
/// left that stays visible even while working in another app. The filled
/// portion shimmers, like a terminal spinner, to read as "still going" at a
/// glance rather than a static bar; it speeds up once under a minute is left,
/// and freezes while paused. Purely decorative: the window that hosts this
/// ignores every mouse event, so it never gets in the way.
struct PulsingBorderView: View {
    let state: BorderState

    private var tint: Color {
        state.isPaused ? .secondary : (state.isUrgent ? .flowUrgent : .flowAccent)
    }

    /// Seconds for one full sweep of the shimmer around the loop.
    private var shimmerPeriod: Double {
        state.isUrgent ? 1.1 : 3.2
    }

    private var strokeStyle: StrokeStyle {
        StrokeStyle(lineWidth: Token.Border.lineWidth, lineCap: .round)
    }

    var body: some View {
        let progress = max(0, min(1, state.progress))

        ZStack {
            Rectangle()
                .stroke(.quaternary, lineWidth: Token.Border.lineWidth)

            TimelineView(.animation(paused: state.isPaused)) { context in
                let phase = (context.date.timeIntervalSinceReferenceDate / shimmerPeriod)
                    .truncatingRemainder(dividingBy: 1)

                Rectangle()
                    .stroke(shimmer(at: phase), style: strokeStyle)
                    .mask(
                        Rectangle()
                            .trim(from: 0, to: progress)
                            .stroke(style: strokeStyle)
                    )
            }
            .animation(Token.Motion.progress, value: progress)
            .animation(Token.Motion.phase, value: tint)
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }

    /// A band of brightness chasing around the loop rather than a flat
    /// color — `AngularGradient` shades purely by angle from the center, so
    /// rotating its start/end doesn't distort the rectangle underneath it.
    private func shimmer(at phase: Double) -> AngularGradient {
        let band: [Color] = [
            tint.opacity(0.25), tint.opacity(0.55), tint, tint.opacity(0.55), tint.opacity(0.25),
        ]
        let start = Angle.degrees(phase * 360)
        return AngularGradient(
            gradient: Gradient(colors: band),
            center: .center,
            startAngle: start,
            endAngle: start + .degrees(360)
        )
    }
}
