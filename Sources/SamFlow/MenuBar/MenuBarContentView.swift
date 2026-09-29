import AppKit
import SamFlowKit
import SwiftUI

/// The popover under the menu bar item. Shows the current session at a glance
/// and offers only the actions that make sense in the current phase.
struct MenuBarContentView: View {
    let controller: SessionController
    @Environment(\.openWindow) private var openWindow

    @State private var goal = ""
    @FocusState private var goalFieldFocused: Bool

    private var trimmedGoal: String {
        goal.trimmingCharacters(in: .whitespacesAndNewlines)
    }

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

    /// Goal entry, right where the click happened — no separate window stands
    /// between "click the icon" and "start the session".
    private var idle: some View {
        VStack(alignment: .leading, spacing: Token.Space.base) {
            HStack(spacing: Token.Space.base) {
                ZStack {
                    Circle()
                        .fill(Color.flowAccent.opacity(0.15))
                        .frame(width: Token.Ring.miniDiameter, height: Token.Ring.miniDiameter)
                    Image(systemName: "target")
                        .font(.callout)
                        .foregroundStyle(Color.flowAccent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("What is the one goal?")
                        .font(Token.Font.goal)
                    Text("\(Int(controller.defaultDuration / 60)) minutes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }

            TextField("Ship the API doc", text: $goal)
                .textFieldStyle(.plain)
                .focused($goalFieldFocused)
                .onSubmit(start)
                .padding(Token.Space.snug)
                .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: Token.Radius.control))
                .overlay(
                    RoundedRectangle(cornerRadius: Token.Radius.control)
                        .strokeBorder(goalFieldFocused ? Color.flowAccent : .clear, lineWidth: 2)
                )
                .animation(Token.Motion.phase, value: goalFieldFocused)

            Button("Start") { start() }
                .buttonStyle(.borderedProminent)
                .tint(.flowAccent)
                .keyboardShortcut(.defaultAction)
                .disabled(trimmedGoal.isEmpty)
                .frame(maxWidth: .infinity)
        }
        .onAppear { goalFieldFocused = true }
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

            Button("Give up") {
                _ = try? controller.finish(.abandoned)
            }
            .buttonStyle(.plain)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    /// Step three, right here too: the clock ran out, and this popover is the
    /// only surface left to ask "did you reach it?" on — so time-up forces it
    /// open (see `MenuBarController`) instead of activating a window.
    private func review(_ session: FocusSession) -> some View {
        VStack(alignment: .leading, spacing: Token.Space.base) {
            HStack(spacing: Token.Space.base) {
                ZStack {
                    Circle()
                        .fill(Color.flowAccent.opacity(0.15))
                        .frame(width: Token.Ring.miniDiameter, height: Token.Ring.miniDiameter)
                    Image(systemName: "flag.checkered")
                        .font(.callout)
                        .foregroundStyle(Color.flowAccent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Time's up")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(session.goal)
                        .font(Token.Font.goal)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)
            }

            Text("Did you reach it?")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack {
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
        }
    }

    private func start() {
        guard !trimmedGoal.isEmpty else { return }
        try? controller.start(goal: goal)
        goal = ""
    }

    private func open(_ id: String) {
        openWindow(id: id)
        AppEnvironment.activate()
    }
}
