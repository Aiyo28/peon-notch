import SwiftUI

struct CharactersSettingsView: View {
    @State private var selectedPack: String?
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    private var packs: [CharacterPack] {
        CharacterRegistry.shared.packs.values.sorted { $0.id < $1.id }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Pack grid
            ScrollView {
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
                .padding(16)
            }

            Divider()

            // Bottom bar
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
        VStack(spacing: 8) {
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
                .font(.system(size: 11, weight: .medium))
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

            // Preview sound button
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
