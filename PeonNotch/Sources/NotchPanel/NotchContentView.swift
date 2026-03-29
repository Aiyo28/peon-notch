import SwiftUI

struct NotchRootView: View {
    @ObservedObject var viewModel: NotchViewModel
    @ObservedObject var sessionManager: SessionManager
    let onSessionClick: (AgentSession) -> Void

    private var topRadius: CGFloat { viewModel.isOpen ? 0 : 6 }
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

    private var expandedContent: some View {
        VStack(spacing: 0) {
            // Header with gear icon
            HStack {
                Spacer()
                Button(action: { SettingsWindowController.shared.show() }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.4))
                }
                .buttonStyle(.plain)
                .padding(.trailing, 4)
                .padding(.top, 2)
            }
            .padding(.top, 30)
            .padding(.horizontal, 16)

            if visibleSessions.isEmpty {
                emptyState
            } else {
                sessionList
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private var emptyState: some View {
        HStack(spacing: 14) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 36))
                .foregroundStyle(.white.opacity(0.25))
            Text("No active sessions")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var visibleSessions: [AgentSession] {
        switch viewModel.displayMode {
        case .all:
            return Array(sessionManager.sessions.prefix(9))
        case .notification:
            return sessionManager.sessions.filter {
                viewModel.notificationSessionIDs.contains($0.id)
            }
        }
    }

    private var sessionList: some View {
        ScrollView {
            VStack(spacing: 4) {
                ForEach(visibleSessions) { session in
                    SessionRow(session: session)
                        .onTapGesture { onSessionClick(session) }
                }
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

// MARK: - Session Row

struct SessionRow: View {
    let session: AgentSession
    @State private var isHovered = false
    @State private var isEditing = false
    @State private var editName: String = ""
    @State private var editCharacter: String = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(nsImage: CharacterRegistry.shared.portrait(for: session.character))
                    .resizable()
                    .interpolation(.none)
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(statusColor, lineWidth: 2)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(session.displayName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white)

                    Text(session.message.isEmpty ? session.status.label : session.message)
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.5))
                        .lineLimit(1)
                }

                Spacer()

                if isHovered {
                    Button(action: {
                        editName = session.displayName
                        editCharacter = session.character
                        withAnimation(.easeOut(duration: 0.2)) { isEditing.toggle() }
                    }) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity)
                }

                HStack(spacing: 4) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 7, height: 7)
                    Text(session.status.label)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(statusColor)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(statusColor.opacity(0.15)))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            // Inline edit panel
            if isEditing {
                VStack(spacing: 8) {
                    HStack {
                        TextField("Name", text: $editName)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 12))
                            .onSubmit { applyChanges() }

                        Picker("", selection: $editCharacter) {
                            ForEach(CharacterRegistry.shared.availableNames(), id: \.self) { name in
                                HStack {
                                    Image(nsImage: CharacterRegistry.shared.portrait(for: name))
                                        .resizable()
                                        .frame(width: 16, height: 16)
                                    Text(CharacterRegistry.shared.packs[name]?.name ?? name)
                                }
                                .tag(name)
                            }
                        }
                        .frame(width: 150)

                        Button("Apply") { applyChanges() }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.white.opacity(isHovered ? 0.12 : 0.07))
        )
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.15), value: isHovered)
    }

    private func applyChanges() {
        SessionManager.shared.renameSession(sessionID: session.id, name: editName)
        SessionManager.shared.updateCharacter(sessionID: session.id, character: editCharacter)
        withAnimation { isEditing = false }
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
