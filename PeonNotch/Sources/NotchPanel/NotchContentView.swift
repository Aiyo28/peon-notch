import SwiftUI

// MARK: - Root View (handles the notch shape + animation)

struct NotchRootView: View {
    @ObservedObject var viewModel: NotchViewModel
    @ObservedObject var sessionManager: SessionManager
    let onSessionClick: (AgentSession) -> Void

    @State private var isHovering = false

    private var topRadius: CGFloat { viewModel.isOpen ? 19 : 6 }
    private var bottomRadius: CGFloat { viewModel.isOpen ? 24 : 14 }

    private var openAnimation: Animation {
        .spring(response: 0.42, dampingFraction: 0.8, blendDuration: 0)
    }
    private var closeAnimation: Animation {
        .spring(response: 0.45, dampingFraction: 1.0, blendDuration: 0)
    }

    var body: some View {
        VStack(spacing: 0) {
            // The notch pill — anchored to the top of the window
            notchBody
                .frame(width: viewModel.notchWidth, height: viewModel.notchHeight)
                .clipShape(NotchShape(topRadius: topRadius, bottomRadius: bottomRadius))
                .shadow(
                    color: viewModel.isOpen ? .black.opacity(0.5) : .clear,
                    radius: 8, y: 4
                )
                .onTapGesture {
                    withAnimation(viewModel.isOpen ? closeAnimation : openAnimation) {
                        if viewModel.isOpen { viewModel.close() } else { viewModel.open() }
                    }
                }
                .onHover { hovering in
                    isHovering = hovering
                }
                .animation(viewModel.isOpen ? openAnimation : closeAnimation, value: viewModel.notchWidth)
                .animation(viewModel.isOpen ? openAnimation : closeAnimation, value: viewModel.notchHeight)
                .animation(viewModel.isOpen ? openAnimation : closeAnimation, value: topRadius)
                .animation(viewModel.isOpen ? openAnimation : closeAnimation, value: bottomRadius)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .preferredColorScheme(.dark)
    }

    private var notchBody: some View {
        ZStack {
            // Black background — blends with physical notch
            Color.black

            if viewModel.isOpen {
                expandedContent
                    .transition(
                        .scale(scale: 0.85, anchor: .top)
                        .combined(with: .opacity)
                    )
            } else {
                collapsedContent
            }
        }
    }

    // MARK: - Collapsed (camouflaged as notch)

    private var collapsedContent: some View {
        HStack(spacing: 6) {
            if !sessionManager.sessions.isEmpty {
                // Show tiny dots for each active session
                ForEach(sessionManager.sessions.prefix(6)) { session in
                    Circle()
                        .fill(statusColor(for: session.status))
                        .frame(width: 6, height: 6)
                }
            }
        }
        .padding(.top, 4)
    }

    // MARK: - Expanded

    private var expandedContent: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Text("Peon Notch")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
                Text("\(sessionManager.sessions.count) agent\(sessionManager.sessions.count == 1 ? "" : "s")")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            if sessionManager.sessions.isEmpty {
                emptyState
            } else {
                sessionGrid
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 28))
                .foregroundStyle(.white.opacity(0.2))
            Text("No active sessions")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.4))
            Text("Start a Claude Code session")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.25))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var sessionGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
        return ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(sessionManager.sessions) { session in
                    SessionCard(session: session)
                        .onTapGesture { onSessionClick(session) }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }

    private func statusColor(for status: AgentStatus) -> Color {
        switch status {
        case .working: return .green
        case .idle: return .gray
        case .error: return .red
        case .inputRequired: return .yellow
        }
    }
}

// MARK: - Session Card

struct SessionCard: View {
    let session: AgentSession

    var body: some View {
        VStack(spacing: 6) {
            Image(nsImage: CharacterRegistry.shared.portrait(for: session.character))
                .resizable()
                .interpolation(.none)
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(statusColor, lineWidth: 2)
                )

            Text(session.character)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(1)

            Text(session.message.isEmpty ? session.status.label : session.message)
                .font(.system(size: 9))
                .foregroundStyle(.white.opacity(0.5))
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.08))
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
