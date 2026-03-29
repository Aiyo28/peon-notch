import SwiftUI
import ServiceManagement

struct GeneralSettingsView: View {
    @State private var launchAtLogin = false
    @State private var defaultCharacter: String = AppSettings.shared.defaultCharacter
    @State private var rotationMode: CharacterRotation = AppSettings.shared.characterRotation

    private var availableCharacters: [String] {
        CharacterRegistry.shared.availableNames()
    }

    var body: some View {
        Form {
            Section("Startup") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        setLaunchAtLogin(newValue)
                    }
            }

            Section("Character") {
                Picker("Default character", selection: $defaultCharacter) {
                    ForEach(availableCharacters, id: \.self) { name in
                        HStack {
                            Image(nsImage: CharacterRegistry.shared.portrait(for: name))
                                .resizable()
                                .frame(width: 20, height: 20)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                            Text(CharacterRegistry.shared.packs[name]?.name ?? name.capitalized)
                        }
                        .tag(name)
                    }
                }
                .onChange(of: defaultCharacter) { _, newValue in
                    AppSettings.shared.defaultCharacter = newValue
                }

                Picker("Rotation mode", selection: $rotationMode) {
                    Text("Fixed").tag(CharacterRotation.fixed)
                    Text("Sequential").tag(CharacterRotation.sequential)
                    Text("Random").tag(CharacterRotation.random)
                }
                .pickerStyle(.segmented)
                .onChange(of: rotationMode) { _, newValue in
                    AppSettings.shared.characterRotation = newValue
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            launchAtLogin = !enabled
        }
    }
}
