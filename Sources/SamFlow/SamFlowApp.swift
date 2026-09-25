import SamFlowKit
import SwiftUI

@main
struct SamFlowApp: App {
    @State private var controller = AppEnvironment.makeController()

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView(controller: controller)
        } label: {
            MenuBarLabel(controller: controller)
        }
        .menuBarExtraStyle(.window)

        Window("Focus", id: WindowID.focus) {
            FocusWindowView(controller: controller)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 420, height: 280)

        Window("History", id: WindowID.history) {
            HistoryView(controller: controller)
        }
        .defaultSize(width: 460, height: 420)
    }
}

enum WindowID {
    static let focus = "focus"
    static let history = "history"
}
