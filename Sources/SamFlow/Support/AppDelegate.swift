import AppKit

/// SwiftUI quits the app by default once its last `Window` scene closes.
/// With the Focus window gone, History is that last window — but SamFlow is
/// a menu bar app first, and the menu bar item, the running countdown and
/// the screen border all need to survive closing History.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
