import AppKit

struct CharacterPack: Identifiable {
    let id: String
    let name: String
    let portrait: NSImage
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

            packs[folder] = CharacterPack(id: folder, name: displayName(for: folder), portrait: portrait)
        }
    }

    func portrait(for name: String) -> NSImage {
        packs[name]?.portrait ?? generatePlaceholder(for: name)
    }

    func availableNames() -> [String] {
        Array(packs.keys).sorted()
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
