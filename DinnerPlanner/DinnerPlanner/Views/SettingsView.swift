import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationView {
            Form {
                Section("Familien-Kollaboration") {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Noch nicht verfügbar", systemImage: "icloud.slash")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Die Echtzeit-Synchronisation mit der Familie erfordert einen bezahlten Apple Developer Account (99 $/Jahr) für iCloud & CloudKit.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Link("Mehr erfahren → developer.apple.com",
                             destination: URL(string: "https://developer.apple.com/programs/")!)
                            .font(.subheadline)
                    }
                    .padding(.vertical, 4)
                }
                Section("Info") {
                    LabeledContent("Version", value: appVersion)
                    LabeledContent("Speicher", value: "Lokal auf diesem Gerät")
                }
            }
            .navigationTitle("Einstellungen")
        }
        .navigationViewStyle(.stack)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}
