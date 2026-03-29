import SwiftUI

enum SettingsTab: String, CaseIterable {
    case general = "General"
    case sound = "Sound"
    case notifications = "Notifications"
    case characters = "Characters"

    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .sound: return "speaker.wave.2"
        case .notifications: return "bell"
        case .characters: return "person.crop.square"
        }
    }
}

struct SettingsView: View {
    @State private var selectedTab: SettingsTab = .general

    var body: some View {
        NavigationSplitView {
            List(SettingsTab.allCases, id: \.self, selection: $selectedTab) { tab in
                Label(tab.rawValue, systemImage: tab.icon)
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 150, ideal: 170)
        } detail: {
            switch selectedTab {
            case .general: GeneralSettingsView()
            case .sound: SoundSettingsView()
            case .notifications: NotificationSettingsView()
            case .characters: CharactersSettingsView()
            }
        }
    }
}
