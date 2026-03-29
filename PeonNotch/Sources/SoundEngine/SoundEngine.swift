import AVFoundation
import Foundation

class SoundEngine {
    static let shared = SoundEngine()

    private var player: AVAudioPlayer?
    private var settings: SoundSettings
    private let settingsPath: String

    // Spam detection
    private var recentEvents: [(event: String, time: Date)] = []

    private init() {
        let configDir = NSHomeDirectory() + "/.config/peon-notch"
        settingsPath = configDir + "/sound-settings.json"

        // Load or create default settings
        if let data = try? Data(contentsOf: URL(fileURLWithPath: settingsPath)),
           let loaded = try? JSONDecoder().decode(SoundSettings.self, from: data) {
            settings = loaded
        } else {
            settings = SoundSettings()
        }
    }

    func play(event: String, character: String) {
        guard settings.enabled, !settings.muted else { return }

        // Check category enabled
        let category = eventCategory(event)
        guard settings.categories[category] ?? true else { return }

        // Spam detection
        if isSpamming(event: event) { return }

        // Find sound file
        guard let soundURL = findSound(event: event, character: character) else { return }

        do {
            player = try AVAudioPlayer(contentsOf: soundURL)
            player?.volume = settings.volume
            player?.play()
        } catch {
            // Missing sound file — fail silently per spec
        }
    }

    // MARK: - Settings

    var volume: Float {
        get { settings.volume }
        set { settings.volume = max(0, min(1, newValue)); save() }
    }

    var muted: Bool {
        get { settings.muted }
        set { settings.muted = newValue; save() }
    }

    var enabled: Bool {
        get { settings.enabled }
        set { settings.enabled = newValue; save() }
    }

    func setCategoryEnabled(_ category: String, enabled: Bool) {
        settings.categories[category] = enabled
        save()
    }

    func isCategoryEnabled(_ category: String) -> Bool {
        settings.categories[category] ?? true
    }

    // MARK: - Private

    private func findSound(event: String, character: String) -> URL? {
        let charactersDir = NSHomeDirectory() + "/Documents/Developer/peon-notch/characters"

        // Try exact event name first, then category
        let candidates = [
            "\(charactersDir)/\(character)/sounds/\(event).wav",
            "\(charactersDir)/\(character)/sounds/\(event).mp3",
            "\(charactersDir)/\(character)/sounds/\(eventCategory(event)).wav",
            "\(charactersDir)/\(character)/sounds/\(eventCategory(event)).mp3",
        ]

        for path in candidates {
            if FileManager.default.fileExists(atPath: path) {
                return URL(fileURLWithPath: path)
            }
        }
        return nil
    }

    private func eventCategory(_ event: String) -> String {
        // Map events like "session.start" -> "session.start", keep as-is
        event
    }

    private func isSpamming(event: String) -> Bool {
        let now = Date()
        let window = TimeInterval(settings.spamWindowSeconds)

        // Clean old events
        recentEvents.removeAll { now.timeIntervalSince($0.time) > window }

        // Add current
        recentEvents.append((event: event, time: now))

        // Check threshold
        return recentEvents.count > settings.spamThreshold
    }

    private func save() {
        let dir = (settingsPath as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        if let data = try? JSONEncoder().encode(settings) {
            try? data.write(to: URL(fileURLWithPath: settingsPath))
        }
    }
}

struct SoundSettings: Codable {
    var enabled: Bool = true
    var muted: Bool = false
    var volume: Float = 0.5
    var categories: [String: Bool] = [
        "session.start": true,
        "task.complete": true,
        "task.error": true,
        "input.required": true,
    ]
    var spamThreshold: Int = 3
    var spamWindowSeconds: Int = 10
}
