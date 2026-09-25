import AppKit
import SamFlowKit
import SwiftUI

/// Wires the domain to the platform. This is the only place that decides which
/// concrete store and ticker the app runs with, and the only place that reacts
/// to domain events with AppKit calls.
enum AppEnvironment {
    /// Builds the one controller the whole app shares, fully wired. Called once,
    /// when the `App` value is created — never from a view's lifecycle, so the
    /// wiring does not depend on which window happens to open first.
    @MainActor
    static func makeController() -> SessionController {
        let store: any SessionStore
        do {
            store = try JSONFileSessionStore.applicationSupport()
        } catch {
            // History is a nice-to-have; never block a focus session on it.
            NSLog("SamFlow: falling back to in-memory history — \(error)")
            store = InMemorySessionStore()
        }

        let launchConfiguration = LaunchConfiguration.parse()
        let controller = SessionController(
            store: store,
            defaultDuration: launchConfiguration.duration ?? .minutes(25)
        )
        controller.onTimeUp = { _ in
            NSSound.beep()
            activate()
        }
        do {
            try controller.loadHistory()
        } catch {
            NSLog("SamFlow: could not read session history — \(error)")
        }
        return controller
    }

    /// A menu bar app is an accessory, so opening a window is not enough — it
    /// also has to be pulled in front of whatever currently has focus.
    @MainActor
    static func activate() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.windows.first { $0.isVisible && $0.canBecomeMain }?.makeKeyAndOrderFront(nil)
    }
}
