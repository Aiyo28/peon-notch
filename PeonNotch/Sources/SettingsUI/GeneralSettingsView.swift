import SwiftUI
import ServiceManagement

struct GeneralSettingsView: View {
    @State private var launchAtLogin = false
    @State private var defaultCharacter: String = AppSettings.shared.defaultCharacter
    @State private var rotationMode: CharacterRotation = AppSettings.shared.characterRotation
    @State private var rotationCategories: Set<String> = AppSettings.shared.rotationCategories
    @ObservedObject private var sessionManager = SessionManager.shared

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

            if rotationMode != .fixed {
                Section("Rotate from categories") {
                    ForEach(PackCategory.allCases, id: \.self) { category in
                        let isOn = Binding(
                            get: { rotationCategories.contains(category.rawValue) },
                            set: { enabled in
                                if enabled {
                                    rotationCategories.insert(category.rawValue)
                                } else {
                                    rotationCategories.remove(category.rawValue)
                                }
                                AppSettings.shared.rotationCategories = rotationCategories
                            }
                        )
                        Toggle(category.rawValue, isOn: isOn)
                    }

                    if rotationCategories.isEmpty {
                        Text("No filter — rotating through all packs")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if !sessionManager.sessions.isEmpty {
                Section("Active Sessions") {
                    ForEach(sessionManager.sessions) { session in
                        HStack(spacing: 10) {
                            Image(nsImage: CharacterRegistry.shared.portrait(for: session.character))
                                .resizable()
                                .frame(width: 24, height: 24)
                                .clipShape(RoundedRectangle(cornerRadius: 4))

                            VStack(alignment: .leading, spacing: 1) {
                                Text(session.displayName)
                                    .font(.system(size: 12, weight: .medium))
                                Text(session.status.label)
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Picker("", selection: Binding(
                                get: { session.character },
                                set: { newChar in
                                    SessionManager.shared.updateCharacter(sessionID: session.id, character: newChar)
                                }
                            )) {
                                ForEach(availableCharacters, id: \.self) { name in
                                    Text(CharacterRegistry.shared.packs[name]?.name ?? name)
                                        .tag(name)
                                }
                            }
                            .frame(width: 140)
                        }
                    }
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
