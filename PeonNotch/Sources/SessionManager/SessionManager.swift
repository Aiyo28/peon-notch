import Foundation

enum AgentStatus: String, Codable {
    case working
    case idle
    case error
    case inputRequired = "input-required"

    var label: String {
        switch self {
        case .working: return "Working..."
        case .idle: return "Idle"
        case .error: return "Error"
        case .inputRequired: return "Needs input"
        }
    }
}

struct AgentSession: Identifiable, Equatable {
    let id: String          // session ID
    let pid: Int32          // terminal process ID
    var character: String   // character pack name
    var status: AgentStatus
    var message: String
    var lastUpdated: Date

    static func == (lhs: AgentSession, rhs: AgentSession) -> Bool {
        lhs.id == rhs.id
    }
}

class SessionManager: ObservableObject {
    static let shared = SessionManager()
    static let sessionUpdatedNotification = Notification.Name("PeonNotch.sessionUpdated")

    @Published var sessions: [AgentSession] = []

    private var heartbeatTimer: Timer?
    private let heartbeatInterval: TimeInterval = 30

    private init() {
        startHeartbeat()
    }

    func handleEvent(sessionID: String, event: String, character: String, pid: Int32, message: String) {
        DispatchQueue.main.async { [weak self] in
            self?.processEvent(sessionID: sessionID, event: event, character: character, pid: pid, message: message)
        }
    }

    private func processEvent(sessionID: String, event: String, character: String, pid: Int32, message: String) {
        switch event {
        case "session.start":
            let session = AgentSession(
                id: sessionID,
                pid: pid,
                character: character.isEmpty ? "peon" : character,
                status: .working,
                message: message,
                lastUpdated: Date()
            )
            if let index = sessions.firstIndex(where: { $0.id == sessionID }) {
                sessions[index] = session
            } else {
                sessions.append(session)
            }

        case "session.end":
            sessions.removeAll { $0.id == sessionID }

        case "task.complete":
            updateSession(id: sessionID, status: .idle, message: message)

        case "task.error":
            updateSession(id: sessionID, status: .error, message: message)

        case "input.required":
            updateSession(id: sessionID, status: .inputRequired, message: message)

        case "task.start", "subagent.start":
            updateSession(id: sessionID, status: .working, message: message)

        default:
            updateSession(id: sessionID, status: .working, message: message)
        }

        NotificationCenter.default.post(
            name: Self.sessionUpdatedNotification,
            object: nil,
            userInfo: ["event": event, "sessionID": sessionID]
        )
    }

    private func updateSession(id: String, status: AgentStatus, message: String) {
        guard let index = sessions.firstIndex(where: { $0.id == id }) else { return }
        sessions[index].status = status
        if !message.isEmpty {
            sessions[index].message = message
        }
        sessions[index].lastUpdated = Date()
    }

    // MARK: - Heartbeat

    private func startHeartbeat() {
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: heartbeatInterval, repeats: true) { [weak self] _ in
            self?.checkLiveness()
        }
    }

    private func checkLiveness() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.sessions.removeAll { session in
                // kill -0 checks if process exists without sending a signal
                kill(session.pid, 0) != 0
            }
        }
    }
}
