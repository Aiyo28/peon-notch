import Foundation

class AppSettings {
    static let shared = AppSettings()

    private let settingsPath: String
    private var data: SettingsData

    private init() {
        let configDir = NSHomeDirectory() + "/.config/peon-notch"
        settingsPath = configDir + "/settings.json"

        if let raw = try? Data(contentsOf: URL(fileURLWithPath: settingsPath)),
           let loaded = try? JSONDecoder().decode(SettingsData.self, from: raw) {
            data = loaded
        } else {
            data = SettingsData()
        }
    }

    var characterSelectionEnabled: Bool {
        get { data.characterSelectionEnabled }
        set { data.characterSelectionEnabled = newValue; save() }
    }

    var defaultCharacter: String {
        get { data.defaultCharacter }
        set { data.defaultCharacter = newValue; save() }
    }

    var characterRotation: CharacterRotation {
        get { data.characterRotation }
        set { data.characterRotation = newValue; save() }
    }

    var heartbeatInterval: TimeInterval {
        get { data.heartbeatInterval }
        set { data.heartbeatInterval = newValue; save() }
    }

    /// Returns the next character to assign, based on rotation mode
    func nextCharacter(available: [String]) -> String {
        guard !available.isEmpty else { return defaultCharacter }

        switch characterRotation {
        case .fixed:
            return defaultCharacter
        case .sequential:
            let idx = data.rotationIndex % available.count
            data.rotationIndex += 1
            save()
            return available[idx]
        case .random:
            return available.randomElement() ?? defaultCharacter
        }
    }

    private func save() {
        let dir = (settingsPath as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        if let raw = try? JSONEncoder().encode(data) {
            try? raw.write(to: URL(fileURLWithPath: settingsPath))
        }
    }
}

enum CharacterRotation: String, Codable {
    case fixed
    case sequential
    case random
}

struct SettingsData: Codable {
    var characterSelectionEnabled: Bool = false
    var defaultCharacter: String = "peon"
    var characterRotation: CharacterRotation = .random
    var heartbeatInterval: TimeInterval = 30
    var rotationIndex: Int = 0
}
