import AppKit
import SwiftUI

class NotchPanel {
    private let panel: NSPanel
    private let sessionManager: SessionManager
    private let screen: NSScreen
    private let viewModel: NotchViewModel
    private var autoCollapseTimer: Timer?

    init(on screen: NSScreen, sessionManager: SessionManager) {
        self.screen = screen
        self.sessionManager = sessionManager
        self.viewModel = NotchViewModel(screen: screen)

        // Large fixed window — SwiftUI handles the visible size via clip shape
        let windowWidth: CGFloat = 640
        let windowHeight: CGFloat = 400
        let frame = NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight)

        panel = NSPanel(
            contentRect: frame,
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
            backing: .buffered,
            defer: false
        )

        panel.isFloatingPanel = true
        panel.level = NSWindow.Level(Int(CGShieldingWindowLevel()))
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.isMovableByWindowBackground = false
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.appearance = NSAppearance(named: .darkAqua)

        let contentView = NotchRootView(
            viewModel: viewModel,
            sessionManager: sessionManager,
            onSessionClick: { [weak self] session in
                self?.focusTerminal(pid: session.pid)
                self?.viewModel.close()
            }
        )
        panel.contentView = NSHostingView(rootView: contentView)

        positionWindow()
        panel.orderFrontRegardless()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSessionEvent),
            name: SessionManager.sessionUpdatedNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    func toggle() {
        if viewModel.isOpen { viewModel.close() } else { viewModel.open() }
    }

    func expandBriefly(seconds: TimeInterval = 4) {
        viewModel.open(sessionCount: sessionManager.sessions.count)
        autoCollapseTimer?.invalidate()
        autoCollapseTimer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { [weak self] _ in
            self?.viewModel.close()
        }
    }

    @objc private func handleSessionEvent(_ notification: Notification) {
        guard let event = notification.userInfo?["event"] as? String else { return }
        if event != "session.end" {
            expandBriefly()
        }
    }

    @objc private func screenChanged() {
        positionWindow()
    }

    private func positionWindow() {
        let screenFrame = screen.frame
        let windowWidth: CGFloat = 640
        let windowHeight: CGFloat = 400
        let x = screenFrame.origin.x + (screenFrame.width / 2) - windowWidth / 2
        let y = screenFrame.origin.y + screenFrame.height - windowHeight
        panel.setFrame(NSRect(x: x, y: y, width: windowWidth, height: windowHeight), display: true)
    }

    private func focusTerminal(pid: Int32) {
        let app = NSRunningApplication(processIdentifier: pid)
            ?? findParentTerminal(childPid: pid)
        app?.activate()
    }

    private func findParentTerminal(childPid: Int32) -> NSRunningApplication? {
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

// MARK: - ViewModel

class NotchViewModel: ObservableObject {
    @Published var isOpen = false
    @Published var notchWidth: CGFloat
    @Published var notchHeight: CGFloat

    let closedWidth: CGFloat
    let closedHeight: CGFloat
    var sessionCount: Int = 0

    init(screen: NSScreen) {
        let leftPad = screen.auxiliaryTopLeftArea?.width ?? 0
        let rightPad = screen.auxiliaryTopRightArea?.width ?? 0
        closedWidth = screen.frame.width - leftPad - rightPad + 4
        closedHeight = screen.safeAreaInsets.top > 0 ? screen.safeAreaInsets.top : 38
        notchWidth = closedWidth
        notchHeight = closedHeight
    }

    /// Adaptive sizing based on session count
    private var openWidth: CGFloat {
        switch sessionCount {
        case 0:      return 300       // empty state — compact
        case 1:      return 200       // single card
        case 2:      return 340       // two cards side by side
        case 3:      return 480       // three cards in a row
        case 4...6:  return 480       // two rows of 3
        default:     return 560       // 7+ grid
        }
    }

    private var openHeight: CGFloat {
        switch sessionCount {
        case 0:      return 120       // empty state
        case 1...3:  return 140       // single row
        case 4...6:  return 250       // two rows
        default:     return 340       // 3+ rows
        }
    }

    func open(sessionCount: Int = 0) {
        self.sessionCount = sessionCount
        isOpen = true
        notchWidth = openWidth
        notchHeight = openHeight
    }

    func close() {
        isOpen = false
        notchWidth = closedWidth
        notchHeight = closedHeight
    }

    func updateSize(sessionCount: Int) {
        self.sessionCount = sessionCount
        guard isOpen else { return }
        notchWidth = openWidth
        notchHeight = openHeight
    }
}
