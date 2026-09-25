import SamFlowKit
import SwiftUI

/// Step one: name the single goal. One field, one button — anything else here
/// is a decision the user has to make before they can start working.
struct GoalEntryView: View {
    let controller: SessionController

    @State private var goal = ""
    @FocusState private var fieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Token.Space.base) {
            Text("What is the one goal?")
                .font(.headline)

            TextField("Ship the API doc", text: $goal)
                .textFieldStyle(.plain)
                .font(Token.Font.goal)
                .focused($fieldFocused)
                .onSubmit(start)
                .padding(Token.Space.snug)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: Token.Radius.control))

            HStack {
                Text("\(Int(controller.defaultDuration / 60)) minutes")
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Start") { start() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(goal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(Token.Space.loose)
        .onAppear { fieldFocused = true }
    }

    private func start() {
        try? controller.start(goal: goal)
        goal = ""
    }
}
