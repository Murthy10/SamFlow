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
        VStack(spacing: 0) {
            header
            Divider()

            if sessions.isEmpty {
                ContentUnavailableView {
                    Label("No sessions yet", systemImage: "target")
                        .foregroundStyle(Color.flowAccent)
                } description: {
                    Text("Finished sessions show up here.")
                }
            } else {
                List(sessions) { session in
                    HistoryRow(session: session)
                        .padding(.vertical, Token.Space.tight)
                        .padding(.horizontal, Token.Space.snug)
                        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: Token.Radius.card))
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 4, leading: Token.Space.base, bottom: 4, trailing: Token.Space.base))
                        .listRowBackground(Color.clear)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .frame(minWidth: 380, minHeight: 260)
    }

    /// Stands in for the window title, which `.hiddenTitleBar` removes.
    private var header: some View {
        HStack(spacing: Token.Space.tight) {
            Image(systemName: "clock.arrow.circlepath")
                .foregroundStyle(Color.flowAccent)
            Text("History")
                .font(.headline)
            Spacer()
            if !sessions.isEmpty {
                Text("\(sessions.count) session\(sessions.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, Token.Space.base)
        .padding(.vertical, Token.Space.snug)
        // Leaves room for the traffic-light controls, which `.hiddenTitleBar`
        // keeps floating over the top-left of the content.
        .padding(.leading, Token.Space.loose)
    }
}

private struct HistoryRow: View {
    let session: FocusSession

    var body: some View {
        HStack(spacing: Token.Space.base) {
            ZStack {
                Circle()
                    .fill((session.outcome?.tint ?? .secondary).opacity(0.15))
                    .frame(width: 32, height: 32)
                if let outcome = session.outcome {
                    Image(systemName: outcome.symbol)
                        .font(.callout)
                        .foregroundStyle(outcome.tint)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(session.goal)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Text(session.startedAt, format: .dateTime.weekday().hour().minute())
                    Text("·")
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
