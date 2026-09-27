import Observation
import SwiftUI

/// Shared with `ScreenBorderController`: whether the active session is
/// currently paused or in its final minute. A separate `@Observable` object
/// rather than reusing `SessionController` directly, so the border overlay
/// windows only redraw for the two things that change how they look.
@Observable
final class BorderState {
    var isPaused = false
    var isUrgent = false
}

/// The fine pulsing border shown around every screen while a session is
/// active — an ambient reminder of the running goal that stays visible even
/// while working in another app. Purely decorative: the window that hosts
/// this ignores every mouse event, so it never gets in the way.
struct PulsingBorderView: View {
    let state: BorderState

    @State private var pulse = false

    private var tint: Color {
        state.isPaused ? .secondary : (state.isUrgent ? .flowUrgent : .flowAccent)
    }

    var body: some View {
        Rectangle()
            .strokeBorder(tint.opacity(pulse ? 0.7 : 0.3), lineWidth: 3)
            .allowsHitTesting(false)
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: pulse)
            .onAppear { pulse = true }
    }
}
