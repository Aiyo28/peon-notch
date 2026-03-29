import Foundation

class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private let settingsPath: String
    private var data: SettingsData

    static let didChangeNotification = Notification.Name("AppSettings.didChange")

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

    /// Category filter for rotation — only rotate through these categories
    var rotationCategories: Set<String> {
        get { Set(data.rotationCategories) }
        set { data.rotationCategories = Array(newValue).sorted(); save() }
    }

    /// Folder-to-character mapping: cwd path → (name, character)
    var folderMappings: [String: FolderMapping] {
        get { data.folderMappings }
        set { data.folderMappings = newValue; save() }
    }

    /// Returns the next character to assign, based on rotation mode + category filter
    func nextCharacter(available: [String]) -> String {
        guard !available.isEmpty else { return defaultCharacter }

        // Filter by category if any categories are selected
        let filtered: [String]
        if rotationCategories.isEmpty {
            filtered = available
        } else {
            filtered = available.filter { name in
                guard let pack = CharacterRegistry.shared.packs[name] else { return false }
                return rotationCategories.contains(pack.category.rawValue)
            }
        }
        let pool = filtered.isEmpty ? available : filtered

        switch characterRotation {
        case .fixed:
            return defaultCharacter
        case .sequential:
            let idx = data.rotationIndex % pool.count
            data.rotationIndex += 1
            save()
            return pool[idx]
        case .random:
            return pool.randomElement() ?? defaultCharacter
        }
    }

    /// Resolve character and name for a given cwd
    func resolveSession(cwd: String, available: [String]) -> (name: String, character: String) {
        // Check folder mappings
        for (path, mapping) in folderMappings {
            if cwd.hasPrefix(path) || cwd.hasSuffix(path) {
                return (mapping.displayName, mapping.character)
            }
        }
        // Try to extract project name from cwd
        let projectName = URL(fileURLWithPath: cwd).lastPathComponent
        let character = nextCharacter(available: available)
        return (projectName, character)
    }

    func setFolderMapping(path: String, name: String, character: String) {
        data.folderMappings[path] = FolderMapping(displayName: name, character: character)
        save()
    }

    private func save() {
        let dir = (settingsPath as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        if let raw = try? JSONEncoder().encode(data) {
            try? raw.write(to: URL(fileURLWithPath: settingsPath))
        }
        objectWillChange.send()
        NotificationCenter.default.post(name: Self.didChangeNotification, object: nil)
    }
}

enum CharacterRotation: String, Codable, CaseIterable {
    case fixed
    case sequential
    case random
}

struct FolderMapping: Codable {
    var displayName: String
    var character: String
}

struct SettingsData: Codable {
    var characterSelectionEnabled: Bool = false
    var defaultCharacter: String = "peon"
    var characterRotation: CharacterRotation = .random
    var heartbeatInterval: TimeInterval = 30
    var rotationIndex: Int = 0
    var rotationCategories: [String] = []
    var folderMappings: [String: FolderMapping] = [:]
}
