import SwiftUI

struct NotificationSettingsView: View {
    @State private var expandDuration: Double = 4
    @State private var expandOnStart: Bool = true
    @State private var expandOnComplete: Bool = true
    @State private var expandOnError: Bool = true
    @State private var expandOnInput: Bool = true

    var body: some View {
        Form {
            Section("Auto-Expand") {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Duration")
                        Spacer()
                        Text("\(Int(expandDuration))s")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: $expandDuration, in: 2...10, step: 1)
                }
            }

            Section("Expand notch on event") {
                Toggle("Session Start", isOn: $expandOnStart)
                Toggle("Task Complete", isOn: $expandOnComplete)
                Toggle("Task Error", isOn: $expandOnError)
                Toggle("Input Required", isOn: $expandOnInput)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
