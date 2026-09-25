import Foundation
import Testing
@testable import SamFlowKit

/// A clock the test moves by hand, so nothing here waits on real time.
@MainActor
private final class TestClock {
    var now = Date(timeIntervalSince1970: 1_000_000)
    func advance(_ interval: TimeInterval) { now += interval }
}

@MainActor
private func makeController(
    duration: TimeInterval = .minutes(25)
) -> (SessionController, TestClock, ManualTicker, InMemorySessionStore) {
    let clock = TestClock()
    let ticker = ManualTicker()
    let store = InMemorySessionStore()
    let controller = SessionController(
        store: store,
        ticker: ticker,
        defaultDuration: duration,
        now: { clock.now }
    )
    return (controller, clock, ticker, store)
}

@MainActor
@Suite("Session lifecycle")
struct SessionControllerTests {
    @Test("A started session counts down from the planned duration")
    func countsDown() throws {
        let (controller, clock, ticker, _) = makeController()

        try controller.start(goal: "Ship the API doc")
        #expect(controller.remaining == .minutes(25))

        clock.advance(.minutes(10))
        ticker.fire()
        #expect(controller.remaining == .minutes(15))
    }

    @Test("A blank goal is rejected")
    func rejectsBlankGoal() {
        let (controller, _, _, _) = makeController()
        #expect(throws: SessionError.emptyGoal) {
            try controller.start(goal: "   ")
        }
    }

    @Test("Paused time does not count against the clock")
    func pauseExcludesTime() throws {
        let (controller, clock, ticker, _) = makeController()

        try controller.start(goal: "Write the spec")
        clock.advance(.minutes(5))
        try controller.pause()

        clock.advance(.minutes(30))
        #expect(controller.remaining == .minutes(20))

        try controller.resume()
        clock.advance(.minutes(5))
        ticker.fire()
        #expect(controller.remaining == .minutes(15))
    }

    @Test("Reaching zero moves the session into review, not into idle")
    func zeroEntersReview() throws {
        let (controller, clock, ticker, store) = makeController(duration: .minutes(1))
        var notified: FocusSession?
        controller.onTimeUp = { notified = $0 }

        try controller.start(goal: "Inbox zero")
        clock.advance(.minutes(2))
        ticker.fire()

        #expect(controller.remaining == 0)
        #expect(notified?.goal == "Inbox zero")
        if case .review = controller.phase {} else {
            Issue.record("expected .review, got \(controller.phase)")
        }
        // Nothing is written until the user says how it went.
        #expect(try store.load().isEmpty)
    }

    @Test("Finishing writes the outcome to the store and returns to idle")
    func finishPersists() throws {
        let (controller, clock, _, store) = makeController()

        try controller.start(goal: "Ship the API doc")
        clock.advance(.minutes(12))
        let finished = try controller.finish(.achieved)

        #expect(finished.outcome == .achieved)
        #expect(finished.endedAt == clock.now)
        #expect(controller.phase == .idle)
        #expect(controller.history.count == 1)
        #expect(try store.load().first?.goal == "Ship the API doc")
    }

    @Test("Only one session runs at a time")
    func rejectsConcurrentSessions() throws {
        let (controller, _, _, _) = makeController()
        try controller.start(goal: "First")
        #expect(throws: SessionError.sessionAlreadyRunning) {
            try controller.start(goal: "Second")
        }
    }
}

@Suite("Formatting")
struct FormattingTests {
    @Test("Countdown rounds up so the last second is visible")
    func clockString() {
        #expect(TimeInterval(1_500).clockString == "25:00")
        #expect(TimeInterval(62).clockString == "1:02")
        #expect(TimeInterval(0.4).clockString == "0:01")
        #expect(TimeInterval(0).clockString == "0:00")
    }

    @Test("Minutes label rounds to the nearest minute")
    func minutesLabel() {
        #expect(TimeInterval.minutes(25).minutesLabel == "25 min")
        #expect(TimeInterval.minutes(1).minutesLabel == "1 min")
        #expect(TimeInterval(90).minutesLabel == "2 min")
    }
}

@MainActor
@Suite("Configured duration flows into history")
struct ConfiguredDurationTests {
    @Test("A session started under a launch-configured duration records that duration")
    func customDurationPersisted() throws {
        let config = LaunchConfiguration.parse(arguments: ["--duration", "45"], environment: [:])
        let store = InMemorySessionStore()
        let controller = SessionController(
            store: store,
            ticker: ManualTicker(),
            defaultDuration: config.duration ?? .minutes(25)
        )

        try controller.start(goal: "Plan the launch")
        let finished = try controller.finish(.achieved)

        #expect(finished.plannedDuration == .minutes(45))
        #expect(try store.load().first?.plannedDuration == .minutes(45))
    }
}
