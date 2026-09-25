import AppKit
import SamFlowKit
import SwiftUI

/// The popover under the menu bar item. Shows the current session at a glance
/// and offers only the actions that make sense in the current phase.
struct MenuBarContentView: View {
    let controller: SessionController
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: Token.Space.snug) {
            switch controller.phase {
            case .idle:
                idle
            case let .running(session):
                active(session, isPaused: false)
            case let .paused(session, _):
                active(session, isPaused: true)
            case let .review(session):
                review(session)
            }

            Divider()

            HStack {
                Button("History") { open(WindowID.history) }
                Spacer()
                Button("Quit") { NSApplication.shared.terminate(nil) }
            }
            .buttonStyle(.link)
            .font(.callout)
        }
        .padding(Token.Space.base)
        .frame(width: 260)
    }

    private var idle: some View {
        VStack(alignment: .leading, spacing: Token.Space.snug) {
            Text("No session running")
                .foregroundStyle(.secondary)
            Button("Start a session") { open(WindowID.focus) }
                .keyboardShortcut(.defaultAction)
        }
    }

    private func active(_ session: FocusSession, isPaused: Bool) -> some View {
        VStack(alignment: .leading, spacing: Token.Space.snug) {
            Text(session.goal)
                .font(Token.Font.goal)
                .lineLimit(2)

            ProgressView(value: controller.progress)

            HStack {
                Text(controller.remaining.clockString)
                    .monospacedDigit()
                    .foregroundStyle(isPaused ? .secondary : .primary)
                Spacer()
                Button(isPaused ? "Resume" : "Pause") {
                    try? isPaused ? controller.resume() : controller.pause()
                }
                Button("Done") {
                    _ = try? controller.finish(.achieved)
                }
            }
        }
    }

    private func review(_ session: FocusSession) -> some View {
        VStack(alignment: .leading, spacing: Token.Space.snug) {
            Text("Time's up")
                .font(.headline)
            Text(session.goal)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            Button("Review") { open(WindowID.focus) }
                .keyboardShortcut(.defaultAction)
        }
    }

    private func open(_ id: String) {
        openWindow(id: id)
        AppEnvironment.activate()
    }
}
