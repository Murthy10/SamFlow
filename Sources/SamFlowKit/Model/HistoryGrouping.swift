import Foundation

/// One calendar day's worth of sessions, newest first.
public struct HistoryDayGroup: Identifiable, Sendable {
    public let day: Date
    public let sessions: [FocusSession]
    public var id: Date { day }
}

public extension Array where Element == FocusSession {
    /// Groups sessions by the calendar day of `startedAt`. Days come back
    /// newest first, and each day's sessions are newest first within it.
    func groupedByDay(calendar: Calendar = .current) -> [HistoryDayGroup] {
        Dictionary(grouping: self) { calendar.startOfDay(for: $0.startedAt) }
            .map { day, sessions in
                HistoryDayGroup(day: day, sessions: sessions.sorted { $0.startedAt > $1.startedAt })
            }
            .sorted { $0.day > $1.day }
    }
}

public extension Date {
    /// "Today", "Yesterday", or a formatted date — the history section header.
    func historyDayLabel(calendar: Calendar = .current, now: Date = Date()) -> String {
        if calendar.isDate(self, inSameDayAs: now) {
            return "Today"
        }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
           calendar.isDate(self, inSameDayAs: yesterday) {
            return "Yesterday"
        }
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.setLocalizedDateFormatFromTemplate("EEEE, MMM d")
        return formatter.string(from: self)
    }
}
