import Foundation
import Testing
@testable import SamFlowKit

@Suite("History grouped by day")
struct HistoryGroupingTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    private func session(startedAt: Date, goal: String = "goal") -> FocusSession {
        FocusSession(goal: goal, plannedDuration: 60, startedAt: startedAt)
    }

    @Test("Sessions split into one group per calendar day")
    func splitsByDay() {
        let day1 = session(startedAt: Date(timeIntervalSince1970: 0)) // 1970-01-01
        let day2Early = session(startedAt: Date(timeIntervalSince1970: 86_400 + 100))
        let day2Late = session(startedAt: Date(timeIntervalSince1970: 86_400 + 200))

        let groups = [day1, day2Early, day2Late].groupedByDay(calendar: calendar)

        #expect(groups.count == 2)
    }

    @Test("Days come back newest first")
    func newestDayFirst() {
        let earlier = session(startedAt: Date(timeIntervalSince1970: 0))
        let later = session(startedAt: Date(timeIntervalSince1970: 86_400))

        let groups = [earlier, later].groupedByDay(calendar: calendar)

        #expect(groups.map(\.day) == groups.map(\.day).sorted(by: >))
        #expect(groups.first?.sessions.first?.id == later.id)
    }

    @Test("Sessions within a day come back newest first")
    func newestSessionFirstWithinDay() {
        let first = session(startedAt: Date(timeIntervalSince1970: 100))
        let second = session(startedAt: Date(timeIntervalSince1970: 200))

        let groups = [first, second].groupedByDay(calendar: calendar)

        #expect(groups.count == 1)
        #expect(groups[0].sessions.map(\.id) == [second.id, first.id])
    }

    @Test("Today's date is labeled \"Today\"")
    func todayLabel() {
        let now = Date(timeIntervalSince1970: 100_000)
        #expect(now.historyDayLabel(calendar: calendar, now: now) == "Today")
    }

    @Test("The day before now is labeled \"Yesterday\"")
    func yesterdayLabel() {
        let now = Date(timeIntervalSince1970: 100_000)
        let yesterday = now.addingTimeInterval(-86_400)
        #expect(yesterday.historyDayLabel(calendar: calendar, now: now) == "Yesterday")
    }

    @Test("Older days fall back to a formatted date")
    func olderDayLabel() {
        let now = Date(timeIntervalSince1970: 100_000)
        let older = now.addingTimeInterval(-86_400 * 5)
        let label = older.historyDayLabel(calendar: calendar, now: now)
        #expect(label != "Today")
        #expect(label != "Yesterday")
    }
}
