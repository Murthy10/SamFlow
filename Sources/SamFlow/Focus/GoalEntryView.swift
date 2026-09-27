import SamFlowKit
import SwiftUI

/// Step one: name the single goal. One field, one button — anything else here
/// is a decision the user has to make before they can start working.
struct GoalEntryView: View {
    let controller: SessionController

    @State private var goal = ""
    @FocusState private var fieldFocused: Bool

    private var trimmedGoal: String {
        goal.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(spacing: Token.Space.loose) {
            VStack(spacing: Token.Space.snug) {
                ZStack {
                    Circle()
                        .fill(Color.flowAccent.opacity(0.15))
                        .frame(width: 56, height: 56)
                    Image(systemName: "target")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(Color.flowAccent)
                }
                Text("What is the one goal?")
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: Token.Space.snug) {
                TextField("Ship the API doc", text: $goal)
                    .textFieldStyle(.plain)
                    .font(Token.Font.goal)
                    .focused($fieldFocused)
                    .onSubmit(start)
                    .padding(Token.Space.snug)
                    .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: Token.Radius.control))
                    .overlay(
                        RoundedRectangle(cornerRadius: Token.Radius.control)
                            .strokeBorder(fieldFocused ? Color.flowAccent : .clear, lineWidth: 2)
                    )
                    .animation(Token.Motion.phase, value: fieldFocused)

                HStack {
                    Label("\(Int(controller.defaultDuration / 60)) minutes", systemImage: "timer")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, Token.Space.snug)
                        .padding(.vertical, 4)
                        .background(.quaternary.opacity(0.5), in: Capsule())

                    Spacer()

                    Button("Start") { start() }
                        .buttonStyle(.borderedProminent)
                        .tint(.flowAccent)
                        .controlSize(.large)
                        .keyboardShortcut(.defaultAction)
                        .disabled(trimmedGoal.isEmpty)
                }
            }
        }
        .padding(Token.Space.loose)
        .background(
            RadialGradient(
                colors: [Color.flowAccent.opacity(0.08), .clear],
                center: .top,
                startRadius: 10,
                endRadius: 260
            )
        )
        .onAppear { fieldFocused = true }
    }

    private func start() {
        try? controller.start(goal: goal)
        goal = ""
    }
}
