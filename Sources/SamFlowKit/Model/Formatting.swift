import Foundation

public extension TimeInterval {
    /// `18:42` — the countdown format used in the menu bar and the focus window.
    var clockString: String {
        let total = Int(rounded(.up))
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    /// `25 min` — how a session's configured duration is shown in history.
    var minutesLabel: String {
        let minutes = Int((self / 60).rounded())
        return "\(minutes) min"
    }
}
