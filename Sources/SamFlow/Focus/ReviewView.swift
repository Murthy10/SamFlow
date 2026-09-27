import SamFlowKit
import SwiftUI

/// Step three: the clock ran out. One question, two answers — the session is
/// not written to history until the user answers it.
struct ReviewView: View {
    let controller: SessionController
    let session: FocusSession

    @State private var iconAppeared = false

    var body: some View {
        VStack(spacing: Token.Space.loose) {
            ZStack {
                Circle()
                    .fill(Color.flowAccent.opacity(0.15))
                    .frame(width: 64, height: 64)
                Image(systemName: "flag.checkered")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(Color.flowAccent)
                    .symbolEffect(.bounce, value: iconAppeared)
            }
            .onAppear { iconAppeared.toggle() }

            VStack(spacing: 4) {
                Text("Time's up")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text(session.goal)
                    .font(Token.Font.goal)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }

            Text("Did you reach it?")
                .foregroundStyle(.secondary)

            HStack(spacing: Token.Space.snug) {
                Button("Not yet") {
                    _ = try? controller.finish(.missed)
                }
                .buttonStyle(.bordered)

                Button("Yes") {
                    _ = try? controller.finish(.achieved)
                }
                .buttonStyle(.borderedProminent)
                .tint(.flowSuccess)
                .keyboardShortcut(.defaultAction)
            }
            .controlSize(.large)
        }
        .padding(Token.Space.loose)
    }
}
