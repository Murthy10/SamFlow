import SamFlowKit
import SwiftUI

@main
struct SamFlowApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var controller = AppEnvironment.makeController()

    var body: some Scene {
        // The menu bar item itself is plain AppKit (`MenuBarController`,
        // wired in `AppEnvironment`), not a `MenuBarExtra` scene — only
        // AppKit can show its popover on command, which is what lets a
        // finished session put the review prompt in front of the user.

        // With no other scene left in the app, SwiftUI otherwise treats this
        // as the default scene and opens it automatically at launch —
        // suppressed so History only opens when its button is clicked.
        Window("History", id: WindowID.history) {
            HistoryView(controller: controller)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 460, height: 440)
        .defaultLaunchBehavior(.suppressed)
    }
}

enum WindowID {
    static let history = "history"
}
