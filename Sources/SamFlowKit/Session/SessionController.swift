import Foundation

public enum SessionError: Error, Equatable {
    case emptyGoal
    case sessionAlreadyRunning
    case noActiveSession
}

/// The single source of truth for what the app is doing.
///
/// Every view — menu bar, focus window, history — reads this object and calls
/// these methods. Views hold no session state of their own. Nothing here imports
/// SwiftUI or AppKit, so the whole state machine is testable without a UI.
@MainActor
@Observable
public final class SessionController {
    /// What the app is doing right now.
    public private(set) var phase: SessionPhase = .idle
    /// Seconds left on the clock. Recomputed from `Date` on every tick, so it
    /// stays correct across sleep, and stored so SwiftUI has something to observe.
    public private(set) var remaining: TimeInterval
    /// Finished sessions, newest last.
    public private(set) var history: [FocusSession] = []
    /// Length of a session started without an explicit duration.
    public var defaultDuration: TimeInterval

    /// Called once when the clock reaches zero. The app shell uses this to
    /// notify and bring the window forward; the domain stays unaware of both.
    public var onTimeUp: (@MainActor (FocusSession) -> Void)?

    private let store: any SessionStore
    private let ticker: any Ticker
    private let now: @MainActor () -> Date

    public init(
        store: any SessionStore,
        ticker: any Ticker = RunLoopTicker(),
        defaultDuration: TimeInterval = .minutes(25),
        now: @escaping @MainActor () -> Date = { Date() }
    ) {
        self.store = store
        self.ticker = ticker
        self.defaultDuration = defaultDuration
        self.remaining = defaultDuration
        self.now = now
    }

    // MARK: - Commands

    public func start(goal: String, duration: TimeInterval? = nil) throws {
        let trimmed = goal.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw SessionError.emptyGoal }
        guard case .idle = phase else { throw SessionError.sessionAlreadyRunning }

        phase = .running(
            FocusSession(goal: trimmed, plannedDuration: duration ?? defaultDuration, startedAt: now())
        )
        ticker.start(interval: 1) { [weak self] in self?.refresh() }
        refresh()
    }

    public func pause() throws {
        guard case let .running(session) = phase else { throw SessionError.noActiveSession }
        phase = .paused(session, since: now())
        ticker.stop()
        refresh()
    }

    public func resume() throws {
        guard case let .paused(session, since) = phase else { throw SessionError.noActiveSession }
        var resumed = session
        resumed.addPause(now().timeIntervalSince(since))
        phase = .running(resumed)
        ticker.start(interval: 1) { [weak self] in self?.refresh() }
        refresh()
    }

    /// Ends the session and writes it to the log. Valid from any non-idle phase —
    /// the user can declare the goal reached before the clock runs out.
    @discardableResult
    public func finish(_ outcome: SessionOutcome) throws -> FocusSession {
        guard var session = phase.session else { throw SessionError.noActiveSession }
        if case let .paused(_, since) = phase {
            session.addPause(now().timeIntervalSince(since))
        }
        session.finish(outcome: outcome, at: now())

        ticker.stop()
        phase = .idle
        remaining = defaultDuration

        history.append(session)
        try store.append(session)
        return session
    }

    /// Reads the log from disk. Call once at launch.
    public func loadHistory() throws {
        history = try store.load()
    }

    // MARK: - Derived state

    /// 0...1 progress through the planned duration.
    public var progress: Double {
        guard let session = phase.session, session.plannedDuration > 0 else { return 0 }
        return min(1, max(0, 1 - remaining / session.plannedDuration))
    }

    // MARK: - Internals

    /// Recomputes `remaining` from the wall clock and promotes the phase when
    /// the clock hits zero. Called on every tick and after every command.
    private func refresh() {
        switch phase {
        case .idle:
            remaining = defaultDuration

        case let .running(session):
            let left = session.remaining(at: now())
            remaining = left
            if left <= 0 {
                ticker.stop()
                phase = .review(session)
                onTimeUp?(session)
            }

        case let .paused(session, since):
            remaining = session.remaining(at: now(), currentPause: now().timeIntervalSince(since))

        case .review:
            remaining = 0
        }
    }
}

public extension TimeInterval {
    static func minutes(_ count: Double) -> TimeInterval { count * 60 }
}
