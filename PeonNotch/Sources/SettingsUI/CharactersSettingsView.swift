import SwiftUI
import AVFoundation

struct CharactersSettingsView: View {
    @State private var selectedPack: String?
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    private var groupedPacks: [(PackCategory, [CharacterPack])] {
        let all = CharacterRegistry.shared.packs.values
        let grouped = Dictionary(grouping: all) { $0.category }
        return grouped
            .sorted { $0.key < $1.key }
            .map { ($0.key, $0.value.sorted { $0.name < $1.name }) }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(groupedPacks, id: \.0) { category, packs in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(category.rawValue)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.6))
                                .padding(.leading, 4)

                            // Build rows of 3 manually so we can insert detail panel after the right row
                            let rows = stride(from: 0, to: packs.count, by: 3).map {
                                Array(packs[$0..<min($0 + 3, packs.count)])
                            }

                            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                                HStack(spacing: 12) {
                                    ForEach(row) { pack in
                                        PackCard(
                                            pack: pack,
                                            isSelected: selectedPack == pack.id,
                                            isDefault: AppSettings.shared.defaultCharacter == pack.id
                                        )
                                        .onTapGesture {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                                selectedPack = selectedPack == pack.id ? nil : pack.id
                                            }
                                        }
                                    }
                                    // Fill empty slots in last row
                                    if row.count < 3 {
                                        ForEach(0..<(3 - row.count), id: \.self) { _ in
                                            Color.clear.frame(maxWidth: .infinity, minHeight: 150)
                                        }
                                    }
                                }

                                // Detail panel right below this row if selected pack is in it
                                if let selectedPack, row.contains(where: { $0.id == selectedPack }) {
                                    PackDetailView(packID: selectedPack)
                                        .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
                                }
                            }
                        }
                    }
                }
                .padding(16)
            }

            Divider()

            HStack {
                Button("Open Characters Folder") {
                    let path = NSHomeDirectory() + "/Documents/Developer/peon-notch/characters"
                    NSWorkspace.shared.open(URL(fileURLWithPath: path))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Spacer()

                Button("Get More Packs") {
                    NSWorkspace.shared.open(URL(string: "https://www.peonping.com/")!)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(12)
        }
    }
}

// MARK: - Pack Detail View (expanded sound browser)

struct PackDetailView: View {
    let packID: String
    @State private var player: AVAudioPlayer?
    @State private var playingFile: String?

    private var packDir: String {
        NSHomeDirectory() + "/Documents/Developer/peon-notch/characters/\(packID)"
    }

    private var manifest: [String: Any]? {
        for name in ["openpeon.json", "manifest.json"] {
            let path = "\(packDir)/\(name)"
            if let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return json
            }
        }
        return nil
    }

    private var categories: [(String, [[String: Any]])] {
        guard let manifest,
              let cats = manifest["categories"] as? [String: Any] else { return [] }

        let order = ["session.start", "task.acknowledge", "task.complete", "task.error", "input.required", "resource.limit", "user.spam"]
        return order.compactMap { key in
            guard let catData = cats[key] as? [String: Any],
                  let sounds = catData["sounds"] as? [[String: Any]],
                  !sounds.isEmpty else { return nil }
            return (key, sounds)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 12) {
                if let pack = CharacterRegistry.shared.packs[packID] {
                    Image(nsImage: pack.portrait)
                        .resizable()
                        .interpolation(.none)
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(pack.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                        Text("\(totalSoundCount) sounds")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
                Spacer()

                Button("Set as Default") {
                    AppSettings.shared.defaultCharacter = packID
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(AppSettings.shared.defaultCharacter == packID)
            }

            if categories.isEmpty {
                Text("No sound manifest found")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.3))
                    .padding(.vertical, 8)
            } else {
                // Sound categories
                ForEach(categories, id: \.0) { category, sounds in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(categoryLabel(category))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.5))

                        FlowLayout(spacing: 6) {
                            ForEach(sounds.indices, id: \.self) { idx in
                                let sound = sounds[idx]
                                let file = sound["file"] as? String ?? ""
                                let label = sound["label"] as? String ?? soundFileName(file)

                                SoundPill(
                                    label: label,
                                    isPlaying: playingFile == file
                                ) {
                                    playSound(file: file)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private var totalSoundCount: Int {
        categories.reduce(0) { $0 + $1.1.count }
    }

    private func categoryLabel(_ key: String) -> String {
        switch key {
        case "session.start": return "Session Start"
        case "task.acknowledge": return "Acknowledge"
        case "task.complete": return "Task Complete"
        case "task.error": return "Error"
        case "input.required": return "Input Required"
        case "resource.limit": return "Resource Limit"
        case "user.spam": return "Spam"
        default: return key.capitalized
        }
    }

    private func soundFileName(_ file: String) -> String {
        URL(fileURLWithPath: file).deletingPathExtension().lastPathComponent
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
    }

    private func playSound(file: String) {
        let path: String
        if file.contains("/") {
            path = "\(packDir)/\(file)"
        } else {
            path = "\(packDir)/sounds/\(file)"
        }

        guard FileManager.default.fileExists(atPath: path) else { return }

        do {
            player?.stop()
            player = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
            player?.volume = SoundEngine.shared.volume
            player?.play()
            playingFile = file

            // Reset playing state after sound finishes
            DispatchQueue.main.asyncAfter(deadline: .now() + (player?.duration ?? 2)) {
                if playingFile == file { playingFile = nil }
            }
        } catch {}
    }
}

// MARK: - Sound Pill Button

struct SoundPill: View {
    let label: String
    let isPlaying: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: isPlaying ? "speaker.wave.2.fill" : "play.fill")
                    .font(.system(size: 8))
                Text(label)
                    .font(.system(size: 10))
                    .lineLimit(1)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(isPlaying ? .blue.opacity(0.3) : .white.opacity(0.08))
            )
            .foregroundStyle(isPlaying ? .blue : .white.opacity(0.7))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Flow Layout (wrapping horizontal layout)

struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let height = rows.reduce(CGFloat(0)) { result, row in
            result + row.height + (result > 0 ? spacing : 0)
        }
        return CGSize(width: proposal.width ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            for item in row.items {
                subviews[item.index].place(
                    at: CGPoint(x: x, y: y),
                    proposal: ProposedViewSize(item.size)
                )
                x += item.size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct RowItem {
        let index: Int
        let size: CGSize
    }

    private struct Row {
        var items: [RowItem] = []
        var height: CGFloat = 0
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [Row] {
        let maxWidth = proposal.width ?? .infinity
        var rows: [Row] = [Row()]
        var currentWidth: CGFloat = 0

        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            if currentWidth + size.width > maxWidth && !rows[rows.count - 1].items.isEmpty {
                rows.append(Row())
                currentWidth = 0
            }
            rows[rows.count - 1].items.append(RowItem(index: index, size: size))
            rows[rows.count - 1].height = max(rows[rows.count - 1].height, size.height)
            currentWidth += size.width + spacing
        }
        return rows
    }
}

// MARK: - Pack Card

struct PackCard: View {
    let pack: CharacterPack
    let isSelected: Bool
    let isDefault: Bool

    var body: some View {
        VStack(spacing: 6) {
            if isDefault {
                Text("DEFAULT")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.green)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(.green.opacity(0.15)))
            } else {
                Color.clear.frame(height: 16)
            }

            Image(nsImage: pack.portrait)
                .resizable()
                .interpolation(.none)
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(isSelected ? .blue : .clear, lineWidth: 2)
                )

            Text(pack.name)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(1)

            Image(systemName: isSelected ? "chevron.up.circle.fill" : "chevron.down.circle")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(isSelected ? 0.6 : 0.3))
        }
        .frame(maxWidth: .infinity, minHeight: 150, maxHeight: 150)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? .white.opacity(0.12) : .white.opacity(0.06))
        )
    }
}
