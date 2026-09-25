import Foundation

/// The app has exactly one session at a time, and it is always in exactly one of
/// these phases. Every UI surface renders from this value — if a state is not
/// representable here, the UI cannot show it.
public enum SessionPhase: Sendable, Equatable {
    /// Nothing running. The user is choosing a goal.
    case idle
    /// Clock is counting down.
    case running(FocusSession)
    /// Clock is stopped, session still alive. `since` is when the pause began.
    case paused(FocusSession, since: Date)
    /// Time is up. Waiting for the user to say whether the goal was reached.
    case review(FocusSession)

    public var session: FocusSession? {
        switch self {
        case .idle: nil
        case let .running(session), let .paused(session, _), let .review(session): session
        }
    }

    public var isActive: Bool {
        switch self {
        case .running, .paused: true
        case .idle, .review: false
        }
    }
}
