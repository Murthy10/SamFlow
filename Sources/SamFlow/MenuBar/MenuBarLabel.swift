import SamFlowKit
import SwiftUI

/// What sits in the menu bar: the countdown while a session runs, a bare icon
/// otherwise. Kept deliberately narrow so it never pushes other items around.
struct MenuBarLabel: View {
    let controller: SessionController

    var body: some View {
        switch controller.phase {
        case .idle:
            Image(systemName: "target")
        case .running:
            Label(controller.remaining.clockString, systemImage: "target")
                .font(Token.Font.menuBarClock)
        case .paused:
            Label(controller.remaining.clockString, systemImage: "pause.circle")
                .font(Token.Font.menuBarClock)
        case .review:
            Image(systemName: "checkmark.circle")
        }
    }
}
