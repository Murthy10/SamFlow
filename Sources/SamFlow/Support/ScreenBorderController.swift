import AppKit
import Observation
import SamFlowKit
import SwiftUI

/// Owns one borderless, click-through overlay window per screen, each
/// painting the fine pulsing border while a session is running or paused.
/// Purely a platform concern — `SamFlowKit` has no idea this exists, and
/// nothing here changes what a session *is*, only how it looks from outside
/// the app's own windows.
@MainActor
final class ScreenBorderController: NSObject {
    private let session: SessionController
    private let state = BorderState()
    private var overlays: [NSWindow] = []
    private var isShowing = false

    init(observing session: SessionController) {
        self.session = session
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        observe()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /// `withObservationTracking` fires its `onChange` exactly once per
    /// registration, so every callback re-subscribes before doing anything
    /// else — the standard self-rearming pattern for using Observation
    /// outside a SwiftUI view body.
    private func observe() {
        withObservationTracking {
            _ = session.phase
            _ = session.remaining
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                self?.observe()
                self?.refresh()
            }
        }
        refresh()
    }

    private func refresh() {
        let isPaused: Bool
        if case .paused = session.phase { isPaused = true } else { isPaused = false }

        switch session.phase {
        case .running, .paused:
            state.isPaused = isPaused
            state.isUrgent = !isPaused && session.remaining <= Token.Ring.urgentThreshold
            if !isShowing { showOverlays() }
        case .idle, .review:
            hideOverlays()
        }
    }

    private func showOverlays() {
        overlays = NSScreen.screens.map(makeOverlay)
        overlays.forEach { $0.orderFrontRegardless() }
        isShowing = true
    }

    private func hideOverlays() {
        overlays.forEach { $0.orderOut(nil) }
        overlays.removeAll()
        isShowing = false
    }

    @objc private func screenParametersChanged() {
        guard isShowing else { return }
        hideOverlays()
        showOverlays()
    }

    private func makeOverlay(for screen: NSScreen) -> NSWindow {
        let window = BorderOverlayWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false,
            screen: screen
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true
        // Above everything, on every Space, including full-screen apps — the
        // whole point is that it stays visible while working elsewhere.
        window.level = .screenSaver
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        window.contentView = NSHostingView(rootView: PulsingBorderView(state: state))
        return window
    }
}

/// Never takes key or main window status — it must not be clickable or steal
/// focus even if `ignoresMouseEvents` were ever bypassed.
private final class BorderOverlayWindow: NSWindow {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
