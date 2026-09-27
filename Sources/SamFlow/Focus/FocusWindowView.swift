import SamFlowKit
import SwiftUI

/// The one window. It renders whichever step of the loop the session is in —
/// name the goal, work, say how it went — so the user never navigates.
struct FocusWindowView: View {
    let controller: SessionController

    var body: some View {
        Group {
            switch controller.phase {
            case .idle:
                GoalEntryView(controller: controller)
            case .running, .paused:
                ActiveSessionView(controller: controller)
            case let .review(session):
                ReviewView(controller: controller, session: session)
            }
        }
        .frame(minWidth: 400, minHeight: 320)
        .animation(.smooth(duration: 0.2), value: controller.phase)
    }
}
