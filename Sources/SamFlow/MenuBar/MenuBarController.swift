import AppKit
import Observation
import SamFlowKit
import SwiftUI

/// Owns the menu bar item and its popover directly via AppKit rather than
/// SwiftUI's `MenuBarExtra`. Only AppKit can show a popover on command, and
/// that is what lets a finished session put itself in front of the user —
/// the one interruption the product allows, and the only surface the app has
/// left once there is no separate Focus window to activate.
@MainActor
final class MenuBarController: NSObject, NSPopoverDelegate {
    private let session: SessionController
    private let statusItem: NSStatusItem
    private let popover: NSPopover

    init(observing session: SessionController) {
        self.session = session
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        popover = NSPopover()
        super.init()

        popover.behavior = .transient
        popover.delegate = self
        popover.contentViewController = NSHostingController(
            rootView: MenuBarContentView(controller: session)
        )

        if let button = statusItem.button {
            button.imagePosition = .imageLeading
            button.target = self
            button.action = #selector(togglePopover)
        }

        session.onTimeUp = { [weak self] _ in
            NSSound.beep()
            self?.showPopover()
        }

        observeLabel()
    }

    @objc private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            showPopover()
        }
    }

    private func showPopover() {
        guard let button = statusItem.button, !popover.isShown else { return }
        NSApp.activate(ignoringOtherApps: true)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    /// `withObservationTracking` fires its `onChange` exactly once per
    /// registration, so every callback re-subscribes before doing anything
    /// else — the standard self-rearming pattern for using Observation
    /// outside a SwiftUI view body. Mirrors `ScreenBorderController`.
    private func observeLabel() {
        withObservationTracking {
            _ = session.phase
            _ = session.remaining
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                self?.observeLabel()
                self?.refreshLabel()
            }
        }
        refreshLabel()
    }

    private func refreshLabel() {
        guard let button = statusItem.button else { return }

        let symbol: String
        var title = ""
        switch session.phase {
        case .idle:
            symbol = "target"
        case .running:
            symbol = "target"
            title = session.remaining.clockString
        case .paused:
            symbol = "pause.circle"
            title = session.remaining.clockString
        case .review:
            symbol = "checkmark.circle.fill"
        }

        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
        image?.isTemplate = true
        button.image = image
        button.font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.smallSystemFontSize, weight: .medium)
        button.title = title.isEmpty ? "" : " \(title)"
    }
}
