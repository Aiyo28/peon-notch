import Foundation

class CLIReceiver {
    static let notificationName = Notification.Name("com.peon.notch.update")

    func startListening() {
        DistributedNotificationCenter.default().addObserver(
            forName: Self.notificationName,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleNotification(notification)
        }
    }

    private func handleNotification(_ notification: Notification) {
        guard let info = notification.userInfo as? [String: Any] else { return }

        let sessionID = info["session"] as? String ?? ""
        let event = info["event"] as? String ?? ""
        let character = info["character"] as? String ?? ""
        let pid = (info["pid"] as? Int).map { Int32($0) } ?? 0
        let message = info["message"] as? String ?? ""

        guard !sessionID.isEmpty, !event.isEmpty else { return }

        SessionManager.shared.handleEvent(
            sessionID: sessionID,
            event: event,
            character: character,
            pid: pid,
            message: message
        )
    }
}
