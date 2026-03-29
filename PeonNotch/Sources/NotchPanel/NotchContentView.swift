import SwiftUI

struct NotchContentView: View {
    @ObservedObject var sessionManager: SessionManager
    let onSessionClick: (AgentSession) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        VStack(spacing: 0) {
            // Notch indicator bar
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white.opacity(0.3))
                .frame(width: 40, height: 4)
                .padding(.top, 8)

            if sessionManager.sessions.isEmpty {
                emptyState
            } else {
                sessionGrid
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
        )
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("No active sessions")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
            Text("Start a Claude Code session to see agents here")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var sessionGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(sessionManager.sessions) { session in
                    SessionCard(session: session)
                        .onTapGesture { onSessionClick(session) }
                }
            }
            .padding(16)
        }
    }
}

struct SessionCard: View {
    let session: AgentSession

    var body: some View {
        VStack(spacing: 6) {
            // Portrait placeholder — will be replaced with actual images in #3
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(statusColor.opacity(0.2))
                    .frame(width: 64, height: 64)

                Text(session.character.prefix(2).uppercased())
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundStyle(statusColor)

                // Status border
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(statusColor, lineWidth: 2)
                    .frame(width: 64, height: 64)
            }

            Text(session.character)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.primary)
                .lineLimit(1)

            Text(session.message.isEmpty ? session.status.label : session.message)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial.opacity(0.5))
        )
    }

    private var statusColor: Color {
        switch session.status {
        case .working: return .green
        case .idle: return .gray
        case .error: return .red
        case .inputRequired: return .yellow
        }
    }
}
