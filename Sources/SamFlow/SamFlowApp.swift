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
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 420, height: 340)

        Window("History", id: WindowID.history) {
            HistoryView(controller: controller)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 460, height: 440)
    }
}

enum WindowID {
    static let focus = "focus"
    static let history = "history"
}
