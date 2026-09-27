import SamFlowKit
import SwiftUI

/// What sits in the menu bar: the countdown while a session runs, a bare icon
/// otherwise. Kept deliberately narrow so it never pushes other items around.
/// Menu bar glyphs render in the system's monochrome template style, so color
/// is not available here — the little motion on state changes is.
struct MenuBarLabel: View {
    let controller: SessionController

    var body: some View {
        switch controller.phase {
        case .idle:
            Image(systemName: "target")
        case .running:
            Label(controller.remaining.clockString, systemImage: "target")
                .font(Token.Font.menuBarClock)
                .symbolEffect(.pulse)
        case .paused:
            Label(controller.remaining.clockString, systemImage: "pause.circle")
                .font(Token.Font.menuBarClock)
        case .review:
            Image(systemName: "checkmark.circle.fill")
                .symbolEffect(.bounce, value: controller.phase)
        }
    }
}
