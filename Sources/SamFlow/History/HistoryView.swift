import SamFlowKit
import SwiftUI

/// Every finished session, newest first. Read-only on purpose: the log is a
/// record of what happened, not a to-do list to groom.
struct HistoryView: View {
    let controller: SessionController

    private var sessions: [FocusSession] {
        controller.history.reversed()
    }

    var body: some View {
        Group {
            if sessions.isEmpty {
                ContentUnavailableView(
                    "No sessions yet",
                    systemImage: "target",
                    description: Text("Finished sessions show up here.")
                )
            } else {
                List(sessions) { session in
                    HistoryRow(session: session)
                }
                .listStyle(.inset)
            }
        }
        .frame(minWidth: 360, minHeight: 240)
    }
}

private struct HistoryRow: View {
    let session: FocusSession

    var body: some View {
        HStack(spacing: Token.Space.snug) {
            if let outcome = session.outcome {
                Image(systemName: outcome.symbol)
                    .foregroundStyle(outcome.tint)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(session.goal)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Text(session.startedAt, format: .dateTime.weekday().hour().minute())
                    Text("·")
                    // The duration configured for this session — set at launch,
                    // so sessions started under different settings stay legible.
                    Text(session.plannedDuration.minutesLabel)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            if let endedAt = session.endedAt {
                Text(session.focusedTime(at: endedAt).clockString)
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
