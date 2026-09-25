import Foundation

/// One attempt at one goal. Immutable facts about the attempt plus how it ended.
///
/// Time is stored as wall-clock instants, never as an accumulated tick count, so a
/// session survives the machine sleeping or the app being suspended.
public struct FocusSession: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    /// The single thing this session is for. Free text, trimmed, never empty.
    public let goal: String
    public let plannedDuration: TimeInterval
    public let startedAt: Date
    /// When the user finished, gave up, or the clock ran out. `nil` while in progress.
    public private(set) var endedAt: Date?
    public private(set) var outcome: SessionOutcome?
    /// Total time spent paused, accumulated across every pause in this session.
    public private(set) var pausedDuration: TimeInterval

    public init(
        id: UUID = UUID(),
        goal: String,
        plannedDuration: TimeInterval,
        startedAt: Date,
        endedAt: Date? = nil,
        outcome: SessionOutcome? = nil,
        pausedDuration: TimeInterval = 0
    ) {
        self.id = id
        self.goal = goal
        self.plannedDuration = plannedDuration
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.outcome = outcome
        self.pausedDuration = pausedDuration
    }

    /// Focused time from the start of the session up to `date`, excluding pauses.
    public func focusedTime(at date: Date, currentPause: TimeInterval = 0) -> TimeInterval {
        let wall = date.timeIntervalSince(startedAt)
        return max(0, wall - pausedDuration - currentPause)
    }

    /// Time left on the clock at `date`. Clamped to zero — it never goes negative.
    public func remaining(at date: Date, currentPause: TimeInterval = 0) -> TimeInterval {
        max(0, plannedDuration - focusedTime(at: date, currentPause: currentPause))
    }

    public mutating func addPause(_ interval: TimeInterval) {
        pausedDuration += max(0, interval)
    }

    public mutating func finish(outcome: SessionOutcome, at date: Date) {
        self.outcome = outcome
        self.endedAt = date
    }
}

/// How a session ended. Recorded for every finished session — this is the
/// feedback signal the history view is built on.
public enum SessionOutcome: String, Codable, CaseIterable, Sendable {
    /// The goal was reached.
    case achieved
    /// The clock ran out or the user stopped, and the goal was not reached.
    case missed
    /// The user walked away from the session itself, not just the goal.
    case abandoned
}
