import SwiftUI

struct SoundSettingsView: View {
    @State private var volume: Float = SoundEngine.shared.volume
    @State private var muted: Bool = SoundEngine.shared.muted
    @State private var sessionStart: Bool = SoundEngine.shared.isCategoryEnabled("session.start")
    @State private var taskComplete: Bool = SoundEngine.shared.isCategoryEnabled("task.complete")
    @State private var taskError: Bool = SoundEngine.shared.isCategoryEnabled("task.error")
    @State private var inputRequired: Bool = SoundEngine.shared.isCategoryEnabled("input.required")

    var body: some View {
        Form {
            Section("Volume") {
                HStack {
                    Image(systemName: "speaker.fill")
                        .foregroundStyle(.secondary)
                    Slider(value: $volume, in: 0...1)
                        .onChange(of: volume) { _, newValue in
                            SoundEngine.shared.volume = newValue
                        }
                    Image(systemName: "speaker.wave.3.fill")
                        .foregroundStyle(.secondary)
                }

                Toggle("Mute all sounds", isOn: $muted)
                    .onChange(of: muted) { _, newValue in
                        SoundEngine.shared.muted = newValue
                    }
            }

            Section("Sound Categories") {
                categoryRow("Session Start", category: "session.start", enabled: $sessionStart)
                categoryRow("Task Complete", category: "task.complete", enabled: $taskComplete)
                categoryRow("Task Error", category: "task.error", enabled: $taskError)
                categoryRow("Input Required", category: "input.required", enabled: $inputRequired)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func categoryRow(_ label: String, category: String, enabled: Binding<Bool>) -> some View {
        HStack {
            Toggle(label, isOn: enabled)
                .onChange(of: enabled.wrappedValue) { _, newValue in
                    SoundEngine.shared.setCategoryEnabled(category, enabled: newValue)
                }
            Spacer()
            Button("Preview") {
                let character = AppSettings.shared.defaultCharacter
                SoundEngine.shared.play(event: category, character: character)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }
}
