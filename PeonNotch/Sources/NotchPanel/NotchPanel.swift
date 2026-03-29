import AppKit
import SwiftUI

class NotchPanel {
    private let panel: NSPanel
    private let sessionManager: SessionManager
    private let screen: NSScreen
    private var isExpanded = false
    private var autoCollapseTimer: Timer?

    private let collapsedHeight: CGFloat = 8
    private let expandedHeight: CGFloat = 320
    private let panelWidth: CGFloat = 380

    init(on screen: NSScreen, sessionManager: SessionManager) {
        self.screen = screen
        self.sessionManager = sessionManager

        let frame = NSRect(x: 0, y: 0, width: panelWidth, height: collapsedHeight)
        panel = NSPanel(
            contentRect: frame,
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
            backing: .buffered,
            defer: false
        )

        panel.isFloatingPanel = true
        panel.level = .statusBar + 1
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isMovableByWindowBackground = false
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden

        let contentView = NotchContentView(sessionManager: sessionManager, onSessionClick: { [weak self] session in
            self?.focusTerminal(pid: session.pid)
            self?.collapse()
        })
        panel.contentView = NSHostingView(rootView: contentView)

        positionAtNotch(expanded: false)
        panel.orderFrontRegardless()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSessionEvent),
            name: SessionManager.sessionUpdatedNotification,
            object: nil
        )
    }

    func toggle() {
        if isExpanded { collapse() } else { expand() }
    }

    func expand() {
        guard !isExpanded else { return }
        isExpanded = true
        autoCollapseTimer?.invalidate()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            positionAtNotch(expanded: true, animated: true)
        }
    }

    func collapse() {
        guard isExpanded else { return }
        isExpanded = false
        autoCollapseTimer?.invalidate()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            positionAtNotch(expanded: false, animated: true)
        }
    }

    func expandBriefly(seconds: TimeInterval = 4) {
        expand()
        autoCollapseTimer?.invalidate()
        autoCollapseTimer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { [weak self] _ in
            self?.collapse()
        }
    }

    @objc private func handleSessionEvent(_ notification: Notification) {
        guard let event = notification.userInfo?["event"] as? String else { return }
        if event != "session.end" {
            expandBriefly()
        }
    }

    private func positionAtNotch(expanded: Bool, animated: Bool = false) {
        let notchWidth = screen.notchWidth
        let width = max(panelWidth, notchWidth + 40)
        let height = expanded ? expandedHeight : collapsedHeight

        let x = screen.frame.midX - width / 2
        let y = screen.frame.maxY - height - screen.notchHeight

        let frame = NSRect(x: x, y: y, width: width, height: height)
        if animated {
            panel.animator().setFrame(frame, display: true)
        } else {
            panel.setFrame(frame, display: true)
        }
    }

    private func focusTerminal(pid: Int32) {
        // The PID is the Claude Code process; find its parent terminal app
        let app = NSRunningApplication(processIdentifier: pid)
            ?? findParentTerminal(childPid: pid)
        app?.activate()
    }

    private func findParentTerminal(childPid: Int32) -> NSRunningApplication? {
        // Walk up the process tree to find Warp, Terminal, or iTerm
        let terminalBundleIDs = [
            "dev.warp.Warp-Stable",
            "com.apple.Terminal",
            "com.googlecode.iterm2",
        ]
        for bundleID in terminalBundleIDs {
            if let app = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first {
                return app
            }
        }
        return nil
    }
}
