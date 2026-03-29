import AppKit

struct CharacterPack: Identifiable {
    let id: String
    let name: String
    let portrait: NSImage
    let category: PackCategory
}

enum PackCategory: String, CaseIterable, Comparable {
    case warcraft = "Warcraft"
    case starcraft = "StarCraft"
    case movies = "Movies & TV"
    case games = "Other Games"

    static func < (lhs: PackCategory, rhs: PackCategory) -> Bool {
        let order: [PackCategory] = [.warcraft, .starcraft, .movies, .games]
        return (order.firstIndex(of: lhs) ?? 0) < (order.firstIndex(of: rhs) ?? 0)
    }
}

class CharacterRegistry {
    static let shared = CharacterRegistry()
    private(set) var packs: [String: CharacterPack] = [:]
    private let charactersPath: String

    private init() {
        let candidates = [
            Bundle.main.executableURL?.deletingLastPathComponent().appendingPathComponent("characters").path,
            NSHomeDirectory() + "/Documents/Developer/peon-notch/characters",
        ].compactMap { $0 }

        charactersPath = candidates.first { FileManager.default.fileExists(atPath: $0) }
            ?? NSHomeDirectory() + "/Documents/Developer/peon-notch/characters"

        loadPacks()
    }

    func loadPacks() {
        packs.removeAll()
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(atPath: charactersPath) else { return }

        for folder in contents where !folder.hasPrefix(".") {
            let folderPath = (charactersPath as NSString).appendingPathComponent(folder)
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: folderPath, isDirectory: &isDir), isDir.boolValue else { continue }

            let portraitPath = (folderPath as NSString).appendingPathComponent("portrait.png")
            let portrait = NSImage(contentsOfFile: portraitPath) ?? generatePlaceholder(for: folder)

            let lang = languageTag(for: folder)
            let name = displayName(for: folder) + (lang.isEmpty ? "" : " (\(lang))")
            packs[folder] = CharacterPack(id: folder, name: name, portrait: portrait, category: packCategory(for: folder))
        }
    }

    func portrait(for name: String) -> NSImage {
        packs[name]?.portrait ?? generatePlaceholder(for: name)
    }

    func availableNames() -> [String] {
        Array(packs.keys).sorted()
    }

    private func packCategory(for folder: String) -> PackCategory {
        switch folder {
        case let f where f.hasPrefix("sc_"): return .starcraft
        case let f where f.hasPrefix("wc3_"): return .warcraft
        case "peon", "peon_ru", "peasant", "peasant_ru", "grunt",
             "acolyte_ru", "brewmaster_ru", "high_elf_builder_ru",
             "footman", "arthas", "thrall", "jaina", "tauren_chieftain":
            return .warcraft
        case "arnold", "jarvis", "glados": return .movies
        case "counterstrike", "marine": return .games
        default: return .games
        }
    }

    private func languageTag(for folder: String) -> String {
        if folder.hasSuffix("_ru") { return "RU" }
        return ""
    }

    private func displayName(for folder: String) -> String {
        folder
            .replacingOccurrences(of: "wc3_", with: "")
            .replacingOccurrences(of: "sc_", with: "")
            .replacingOccurrences(of: "_ru", with: "")
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }

    private func generatePlaceholder(for name: String) -> NSImage {
        let size = NSSize(width: 64, height: 64)
        let image = NSImage(size: size)
        image.lockFocus()

        let hash = abs(name.hashValue)
        let hue = CGFloat(hash % 360) / 360.0
        NSColor(hue: hue, saturation: 0.6, brightness: 0.7, alpha: 1.0).setFill()
        NSBezierPath(roundedRect: NSRect(origin: .zero, size: size), xRadius: 8, yRadius: 8).fill()

        let initials = String(name.prefix(2)).uppercased()
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 24, weight: .bold),
            .foregroundColor: NSColor.white,
        ]
        let textSize = (initials as NSString).size(withAttributes: attrs)
        let textRect = NSRect(
            x: (size.width - textSize.width) / 2,
            y: (size.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        (initials as NSString).draw(in: textRect, withAttributes: attrs)
        image.unlockFocus()
        return image
    }
}
