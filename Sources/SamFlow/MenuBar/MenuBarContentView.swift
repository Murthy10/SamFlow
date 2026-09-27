import AppKit
import SamFlowKit
import SwiftUI

/// The popover under the menu bar item. Shows the current session at a glance
/// and offers only the actions that make sense in the current phase.
struct MenuBarContentView: View {
    let controller: SessionController
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: Token.Space.base) {
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
                Button {
                    open(WindowID.history)
                } label: {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
                Spacer()
                Button(role: .destructive) {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Label("Quit", systemImage: "power")
                }
            }
            .buttonStyle(.borderless)
            .labelStyle(.titleAndIcon)
            .font(.callout)
            .foregroundStyle(.secondary)
        }
        .padding(Token.Space.base)
        .frame(width: 280)
    }

    private var idle: some View {
        VStack(spacing: Token.Space.snug) {
            Image(systemName: "target")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("No session running")
                .foregroundStyle(.secondary)
            Button("Start a session") { open(WindowID.focus) }
                .buttonStyle(.borderedProminent)
                .tint(.flowAccent)
                .keyboardShortcut(.defaultAction)
        }
        .frame(maxWidth: .infinity)
    }

    private func active(_ session: FocusSession, isPaused: Bool) -> some View {
        let isUrgent = !isPaused && controller.remaining <= Token.Ring.urgentThreshold

        return VStack(alignment: .leading, spacing: Token.Space.base) {
            HStack(spacing: Token.Space.base) {
                ZStack {
                    CountdownRing(
                        progress: controller.progress,
                        lineWidth: Token.Ring.miniLineWidth,
                        isPaused: isPaused,
                        isUrgent: isUrgent
                    )
                    Image(systemName: isPaused ? "pause.fill" : "target")
                        .font(.caption2)
                        .foregroundStyle(isPaused ? .secondary : Color.flowAccent)
                }
                .frame(width: Token.Ring.miniDiameter, height: Token.Ring.miniDiameter)

                VStack(alignment: .leading, spacing: 2) {
                    Text(session.goal)
                        .font(Token.Font.goal)
                        .lineLimit(2)
                    Text(controller.remaining.clockString)
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundStyle(isUrgent ? Color.flowUrgent : Color.secondary)
                }

                Spacer(minLength: 0)
            }

            HStack {
                Button(isPaused ? "Resume" : "Pause") {
                    try? isPaused ? controller.resume() : controller.pause()
                }
                .buttonStyle(.bordered)
                .tint(.flowAccent)

                Button("Done") {
                    _ = try? controller.finish(.achieved)
                }
                .buttonStyle(.borderedProminent)
                .tint(.flowSuccess)
            }
        }
    }

    private func review(_ session: FocusSession) -> some View {
        VStack(alignment: .leading, spacing: Token.Space.snug) {
            Label("Time's up", systemImage: "flag.checkered")
                .font(.headline)
                .foregroundStyle(Color.flowAccent)
            Text(session.goal)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            Button("Review") { open(WindowID.focus) }
                .buttonStyle(.borderedProminent)
                .tint(.flowAccent)
                .keyboardShortcut(.defaultAction)
        }
    }

    private func open(_ id: String) {
        openWindow(id: id)
        AppEnvironment.activate()
    }
}
