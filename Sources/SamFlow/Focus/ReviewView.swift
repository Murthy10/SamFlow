import SamFlowKit
import SwiftUI

/// Step three: the clock ran out. One question, two answers — the session is
/// not written to history until the user answers it.
struct ReviewView: View {
    let controller: SessionController
    let session: FocusSession

    var body: some View {
        VStack(spacing: Token.Space.base) {
            Text("Time's up")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(session.goal)
                .font(Token.Font.goal)
                .multilineTextAlignment(.center)
                .lineLimit(3)

            Text("Did you reach it?")

            HStack(spacing: Token.Space.snug) {
                Button("Not yet") { _ = try? controller.finish(.missed) }
                Button("Yes") { _ = try? controller.finish(.achieved) }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(Token.Space.loose)
    }
}
