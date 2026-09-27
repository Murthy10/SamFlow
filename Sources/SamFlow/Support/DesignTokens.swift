import SwiftUI

/// Every spacing, radius, type and motion choice in the app comes from here.
/// Views do not hardcode numbers — that is what keeps the three surfaces
/// looking like one app as features land.
enum Token {
    enum Space {
        static let tight: CGFloat = 6
        static let snug: CGFloat = 10
        static let base: CGFloat = 16
        static let loose: CGFloat = 24
    }

    enum Radius {
        static let control: CGFloat = 8
        static let panel: CGFloat = 12
        static let card: CGFloat = 14
    }

    enum Font {
        /// The big countdown. Monospaced digits so it does not jitter every second.
        static let countdown = SwiftUI.Font.system(size: 52, weight: .light, design: .rounded)
            .monospacedDigit()
        static let menuBarClock = SwiftUI.Font.system(size: 12, weight: .medium).monospacedDigit()
        static let goal = SwiftUI.Font.system(.title3, design: .rounded).weight(.medium)
    }

    /// Sizing for `CountdownRing`, the circular progress indicator used in
    /// both the focus window and (at a smaller scale) the menu bar popover.
    enum Ring {
        static let diameter: CGFloat = 210
        static let lineWidth: CGFloat = 12
        static let miniDiameter: CGFloat = 44
        static let miniLineWidth: CGFloat = 4
        /// Below this, the ring and the countdown switch to the urgent color —
        /// a color shift that signals the ending is close without a sound.
        static let urgentThreshold: TimeInterval = 60
    }

    /// Sizing for `PulsingBorderView`, the screen-edge overlay that traces the
    /// session's progress while it runs.
    enum Border {
        static let lineWidth: CGFloat = 3
    }

    enum Motion {
        static let progress = Animation.smooth(duration: 0.5)
        static let phase = Animation.smooth(duration: 0.25)
    }
}
