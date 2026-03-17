import SwiftUI
import SwiftData
import CloudKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var groups: [FamilyGroup]
    @StateObject private var sharingService = CloudKitSharingService()

    @State private var showingCreateGroup = false
    @State private var newGroupName = ""
    @State private var showingQRCode = false
    @State private var showingShareSheet = false

    private var group: FamilyGroup? { groups.first }

    var body: some View {
        NavigationStack {
            Form {
                Section("Familien-Gruppe") {
                    if let group {
                        LabeledContent("Gruppe", value: group.name)

                        if let urlString = group.shareURLString ?? sharingService.shareURL?.absoluteString {
                            Button {
                                showingQRCode = true
                            } label: {
                                Label("QR-Code anzeigen", systemImage: "qrcode")
                            }

                            Button {
                                showingShareSheet = true
                            } label: {
                                Label("Einladungslink teilen", systemImage: "square.and.arrow.up")
                            }
                            .sheet(isPresented: $showingShareSheet) {
                                ShareSheet(items: [urlString])
                            }

                            if !sharingService.participantNames.isEmpty {
                                Section("Mitglieder") {
                                    ForEach(sharingService.participantNames, id: \.self) { name in
                                        Label(name, systemImage: "person.circle")
                                    }
                                }
                            }
                        } else {
                            Button {
                                Task {
                                    await sharingService.createOrFetchShare(for: group.id.uuidString)
                                    if let url = sharingService.shareURL {
                                        group.shareURLString = url.absoluteString
                                    }
                                }
                            } label: {
                                Label("Gruppe mit Familie teilen", systemImage: "person.2.badge.plus")
                            }
                        }

                        if let error = sharingService.errorMessage {
                            Label(error, systemImage: "exclamationmark.triangle")
                                .foregroundStyle(.orange)
                                .font(.caption)
                        }

                    } else {
                        Text("Noch keine Gruppe angelegt.")
                            .foregroundStyle(.secondary)
                        Button {
                            showingCreateGroup = true
                        } label: {
                            Label("Neue Gruppe erstellen", systemImage: "plus.circle")
                        }
                    }
                }

                Section("Info") {
                    LabeledContent("Version", value: appVersion)
                    LabeledContent("Sync", value: "iCloud / CloudKit")
                }
            }
            .navigationTitle("Einstellungen")
        }
        .alert("Gruppe erstellen", isPresented: $showingCreateGroup) {
            TextField("z.B. Familie Müller", text: $newGroupName)
            Button("Erstellen") { createGroup() }.disabled(newGroupName.isEmpty)
            Button("Abbrechen", role: .cancel) { newGroupName = "" }
        } message: {
            Text("Gib deiner Familien-Gruppe einen Namen.")
        }
        .sheet(isPresented: $showingQRCode) {
            if let urlString = group?.shareURLString ?? sharingService.shareURL?.absoluteString {
                QRCodeView(urlString: urlString, sharingService: sharingService)
            }
        }
        .task {
            if let group, let urlString = group.shareURLString, let url = URL(string: urlString) {
                await sharingService.fetchParticipants(shareURL: url)
            }
        }
    }

    private func createGroup() {
        let g = FamilyGroup(name: newGroupName)
        modelContext.insert(g)
        newGroupName = ""
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}

// MARK: - QR Code View

struct QRCodeView: View {
    let urlString: String
    let sharingService: CloudKitSharingService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Familien-Einladung")
                    .font(.headline)

                if let image = sharingService.generateQRCode(from: urlString) {
                    Image(uiImage: image)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 240, height: 240)
                        .padding()
                        .background(.white, in: RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.08), radius: 8)
                }

                Text("Scanne diesen QR-Code mit dem iPhone eines Familienmitglieds, um gemeinsam Mahlzeiten zu planen.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                ShareLink(item: URL(string: urlString)!) {
                    Label("Link teilen", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("QR-Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
