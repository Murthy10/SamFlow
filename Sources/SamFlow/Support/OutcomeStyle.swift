import SamFlowKit
import SwiftUI

extension SessionOutcome {
    var label: String {
        switch self {
        case .achieved: "Achieved"
        case .missed: "Not yet"
        case .abandoned: "Abandoned"
        }
    }

    var symbol: String {
        switch self {
        case .achieved: "checkmark.circle.fill"
        case .missed: "circle.dotted"
        case .abandoned: "xmark.circle"
        }
    }

    var tint: Color {
        switch self {
        case .achieved: .flowSuccess
        case .missed: .flowAccent
        case .abandoned: .secondary
        }
    }
}
