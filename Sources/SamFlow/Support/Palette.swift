import SwiftUI

/// The app's color vocabulary. One fixed hue per meaning, chosen to read
/// clearly on both light and dark system backgrounds, so nothing here needs a
/// per-appearance variant. Everything else (text, chrome, list backgrounds)
/// stays on semantic system colors and materials, which already adapt.
extension Color {
    /// Signature color: an energetic coral used for progress, primary
    /// in-session actions, and small brand touches like the goal-entry icon.
    static let flowAccent = Color(red: 0.98, green: 0.42, blue: 0.20)

    /// Countdown ring and remaining time once under a minute is left.
    static let flowUrgent = Color(red: 0.94, green: 0.24, blue: 0.24)

    /// A goal reached. Used for the "Goal reached" / "Yes" actions and the
    /// achieved badge in history.
    static let flowSuccess = Color(red: 0.16, green: 0.70, blue: 0.43)
}
