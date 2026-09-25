import Foundation

/// Drives the countdown's UI refresh. Abstracted so tests can step time by hand
/// instead of waiting for a real clock.
///
/// A ticker only says *when to look at the clock*. It is never the source of
/// truth for how much time has passed — that is always derived from `Date`.
@MainActor
public protocol Ticker: AnyObject {
    func start(interval: TimeInterval, onTick: @escaping @MainActor () -> Void)
    func stop()
}

/// Production ticker. Scheduled in `.common` run loop mode so it keeps firing
/// while a menu bar popover or a menu is being tracked.
@MainActor
public final class RunLoopTicker: Ticker {
    private var timer: Timer?

    public init() {}

    public func start(interval: TimeInterval, onTick: @escaping @MainActor () -> Void) {
        stop()
        let timer = Timer(timeInterval: interval, repeats: true) { _ in
            MainActor.assumeIsolated { onTick() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    public func stop() {
        timer?.invalidate()
        timer = nil
    }
}

/// Test ticker. `fire()` advances the observer manually.
@MainActor
public final class ManualTicker: Ticker {
    private var onTick: (@MainActor () -> Void)?
    public private(set) var isRunning = false

    public init() {}

    public func start(interval: TimeInterval, onTick: @escaping @MainActor () -> Void) {
        self.onTick = onTick
        isRunning = true
    }

    public func stop() {
        onTick = nil
        isRunning = false
    }

    public func fire() {
        onTick?()
    }
}
