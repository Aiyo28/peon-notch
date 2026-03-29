import Foundation
import AppKit

// Usage: notch-update --session ID --event EVENT --character NAME --pid PID [--message TEXT]

var args = Array(CommandLine.arguments.dropFirst())
var info: [String: Any] = [:]

var i = 0
while i < args.count {
    let arg = args[i]
    guard arg.hasPrefix("--"), i + 1 < args.count else {
        i += 1
        continue
    }
    let key = String(arg.dropFirst(2))
    let value = args[i + 1]

    if let intValue = Int(value) {
        info[key] = intValue
    } else {
        info[key] = value
    }
    i += 2
}

guard info["session"] != nil, info["event"] != nil else {
    print("Usage: notch-update --session ID --event EVENT [--character NAME] [--pid PID] [--message TEXT]")
    exit(1)
}

// Launch app if not running
let bundleID = "com.peon.notch"
if NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).isEmpty {
    // Try common install locations
    let appPaths = [
        "/Applications/PeonNotch.app",
        "\(NSHomeDirectory())/Applications/PeonNotch.app",
        "\(NSHomeDirectory())/Documents/Developer/peon-notch/.build/debug/PeonNotch.app"
    ]
    for path in appPaths {
        let url = URL(fileURLWithPath: path)
        if FileManager.default.fileExists(atPath: path) {
            let config = NSWorkspace.OpenConfiguration()
            config.activates = false
            NSWorkspace.shared.openApplication(at: url, configuration: config) { _, _ in }
            Thread.sleep(forTimeInterval: 1.5)
            break
        }
    }
}

DistributedNotificationCenter.default().postNotificationName(
    Notification.Name("com.peon.notch.update"),
    object: nil,
    userInfo: info,
    deliverImmediately: true
)

// Give notification time to deliver
RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.2))
