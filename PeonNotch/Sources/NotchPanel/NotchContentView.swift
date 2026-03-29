import SwiftUI

// MARK: - Root View

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
            notchBody
                .frame(width: viewModel.notchWidth, height: viewModel.notchHeight)
                .clipShape(NotchShape(topRadius: topRadius, bottomRadius: bottomRadius))
                .shadow(
                    color: viewModel.isOpen ? .black.opacity(0.5) : .clear,
                    radius: 8, y: 4
                )
                .onTapGesture {
                    withAnimation(viewModel.isOpen ? closeAnimation : openAnimation) {
                        if viewModel.isOpen {
                            viewModel.close()
                        } else {
                            viewModel.open(sessionCount: sessionManager.sessions.count)
                        }
                    }
                }
                .onHover { isHovering = $0 }
                .animation(viewModel.isOpen ? openAnimation : closeAnimation, value: viewModel.notchWidth)
                .animation(viewModel.isOpen ? openAnimation : closeAnimation, value: viewModel.notchHeight)
                .animation(viewModel.isOpen ? openAnimation : closeAnimation, value: topRadius)
                .animation(viewModel.isOpen ? openAnimation : closeAnimation, value: bottomRadius)
                .onChange(of: sessionManager.sessions.count) { _, newCount in
                    withAnimation(openAnimation) {
                        viewModel.updateSize(sessionCount: newCount)
                    }
                }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .preferredColorScheme(.dark)
    }

    private var notchBody: some View {
        ZStack {
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

    // MARK: - Collapsed

    private var collapsedContent: some View {
        HStack(spacing: 6) {
            if !sessionManager.sessions.isEmpty {
                ForEach(sessionManager.sessions.prefix(9)) { session in
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
        VStack(spacing: 0) {
            if sessionManager.sessions.isEmpty {
                emptyState
            } else {
                adaptiveLayout
            }
        }
        .padding(.top, 8)
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 22))
                .foregroundStyle(.white.opacity(0.2))
            Text("No active sessions")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Adaptive layout: horizontal row for 1-3, two rows for 4-6, grid for 7+
    @ViewBuilder
    private var adaptiveLayout: some View {
        let sessions = Array(sessionManager.sessions.prefix(9))
        let count = sessions.count

        if count <= 3 {
            // Single horizontal row — compact
            HStack(spacing: 10) {
                ForEach(sessions) { session in
                    CompactCard(session: session)
                        .onTapGesture { onSessionClick(session) }
                }
            }
            .padding(.horizontal, 16)
            .frame(maxHeight: .infinity)
        } else if count <= 6 {
            // Two rows of up to 3
            let row1 = Array(sessions.prefix(3))
            let row2 = Array(sessions.dropFirst(3))
            VStack(spacing: 8) {
                HStack(spacing: 10) {
                    ForEach(row1) { session in
                        CompactCard(session: session)
                            .onTapGesture { onSessionClick(session) }
                    }
                }
                HStack(spacing: 10) {
                    ForEach(row2) { session in
                        CompactCard(session: session)
                            .onTapGesture { onSessionClick(session) }
                    }
                }
            }
            .padding(.horizontal, 16)
            .frame(maxHeight: .infinity)
        } else {
            // 7+ compact grid
            let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
            ScrollView {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(sessions) { session in
                        MiniCard(session: session)
                            .onTapGesture { onSessionClick(session) }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
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

// MARK: - Compact Card (1-6 agents, horizontal layout)

struct CompactCard: View {
    let session: AgentSession

    var body: some View {
        HStack(spacing: 8) {
            Image(nsImage: CharacterRegistry.shared.portrait(for: session.character))
                .resizable()
                .interpolation(.none)
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(statusColor, lineWidth: 2)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(session.character)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(session.message.isEmpty ? session.status.label : session.message)
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.5))
                    .lineLimit(1)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10)
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

// MARK: - Mini Card (7+ agents, grid layout)

struct MiniCard: View {
    let session: AgentSession

    var body: some View {
        VStack(spacing: 4) {
            Image(nsImage: CharacterRegistry.shared.portrait(for: session.character))
                .resizable()
                .interpolation(.none)
                .frame(width: 32, height: 32)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(statusColor, lineWidth: 1.5)
                )

            Text(session.character)
                .font(.system(size: 8, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.white.opacity(0.06))
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
