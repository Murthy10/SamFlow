import SwiftUI

/// Every spacing, radius and type choice in the app comes from here. Views do
/// not hardcode numbers — that is what keeps the three surfaces looking like one
/// app as features land.
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
    }

    enum Font {
        /// The big countdown. Monospaced digits so it does not jitter every second.
        static let countdown = SwiftUI.Font.system(size: 52, weight: .light, design: .rounded)
            .monospacedDigit()
        static let menuBarClock = SwiftUI.Font.system(size: 12, weight: .medium).monospacedDigit()
        static let goal = SwiftUI.Font.system(.title3, design: .rounded).weight(.medium)
    }
}
