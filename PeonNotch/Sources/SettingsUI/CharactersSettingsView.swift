import SwiftUI

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
                            // Category header
                            Text(category.rawValue)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.6))
                                .padding(.leading, 4)

                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(packs) { pack in
                                    PackCard(
                                        pack: pack,
                                        isSelected: selectedPack == pack.id,
                                        isDefault: AppSettings.shared.defaultCharacter == pack.id
                                    )
                                    .onTapGesture { selectedPack = pack.id }
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

struct PackCard: View {
    let pack: CharacterPack
    let isSelected: Bool
    let isDefault: Bool

    var body: some View {
        VStack(spacing: 6) {
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

            if isDefault {
                Text("DEFAULT")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.green)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(.green.opacity(0.15)))
            }

            Button(action: {
                SoundEngine.shared.play(event: "session.start", character: pack.id)
            }) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? .white.opacity(0.12) : .white.opacity(0.06))
        )
    }
}
