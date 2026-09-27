import SwiftUI

/// A circular progress indicator that fills in as a session advances. This is
/// the app's one recurring visual motif — a literal target closing in — used
/// full-size in the focus window and mini in the menu bar popover, so the two
/// surfaces read as the same app at a glance.
struct CountdownRing: View {
    /// 0...1, elapsed fraction of the planned duration.
    let progress: Double
    var lineWidth: CGFloat = Token.Ring.lineWidth
    let isPaused: Bool
    let isUrgent: Bool

    private var tint: Color {
        isPaused ? .secondary : (isUrgent ? .flowUrgent : .flowAccent)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(.quaternary, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(Token.Motion.progress, value: progress)
                .animation(Token.Motion.phase, value: tint)
        }
    }
}
