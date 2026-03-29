import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var notchPanel: NotchPanel!
    private let sessionManager = SessionManager.shared
    private let cliReceiver = CLIReceiver()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupStatusItem()
        setupNotchPanel()
        cliReceiver.startListening()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "person.3.fill", accessibilityDescription: "Peon Notch")
            button.action = #selector(toggleNotch)
            button.target = self
        }
    }

    private func setupNotchPanel() {
        guard let screen = NSScreen.screens.first(where: { $0.hasNotch }) ?? NSScreen.main else { return }
        notchPanel = NotchPanel(on: screen, sessionManager: sessionManager)
    }

    @objc private func toggleNotch() {
        notchPanel.toggle()
    }
}
