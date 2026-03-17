import SwiftUI
import SwiftData

struct ShoppingListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [ShoppingItem]
    @Query private var allEntries: [MealEntry]

    @State private var showingAddItem = false
    @State private var newItemName = ""
    @State private var newItemAmount = ""
    @State private var newItemUnit = ""
    @State private var exportError: String?
    @State private var showingExportSuccess = false
    @State private var isExporting = false

    private var currentWeekID: String { MealEntry.currentWeekID() }
    private var entriesThisWeek: [MealEntry] { allEntries.filter { $0.weekID == currentWeekID } }

    private var unchecked: [ShoppingItem] { items.filter { !$0.isChecked }.sorted { $0.sortOrder < $1.sortOrder } }
    private var checked: [ShoppingItem]   { items.filter { $0.isChecked  }.sorted { $0.sortOrder < $1.sortOrder } }

    var body: some View {
        NavigationStack {
            List {
                if items.isEmpty {
                    Section {
                        ContentUnavailableView(
                            "Keine Einträge",
                            systemImage: "cart",
                            description: Text("Generiere die Liste aus dem Wochenplan oder füge Einträge manuell hinzu.")
                        )
                    }
                    .listRowBackground(Color.clear)
                }

                if !unchecked.isEmpty {
                    Section("Noch kaufen (\(unchecked.count))") {
                        ForEach(unchecked) { item in
                            ShoppingItemRow(item: item)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) { modelContext.delete(item) } label: {
                                        Label("Löschen", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }

                if !checked.isEmpty {
                    Section("Erledigt (\(checked.count))") {
                        ForEach(checked) { item in
                            ShoppingItemRow(item: item)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) { modelContext.delete(item) } label: {
                                        Label("Löschen", systemImage: "trash")
                                    }
                                }
                        }
                        Button(role: .destructive) {
                            for item in checked { modelContext.delete(item) }
                        } label: {
                            Label("Alle erledigten löschen", systemImage: "trash")
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
            .navigationTitle("Einkaufsliste")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    // Regenerate from meal plan
                    Button {
                        regenerateFromPlan()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .help("Aus Wochenplan neu generieren")

                    // Export to Reminders
                    if isExporting {
                        ProgressView()
                    } else {
                        Button {
                            exportToReminders()
                        } label: {
                            Image(systemName: "checkmark.circle")
                        }
                        .help("In Erinnerungen exportieren")
                    }

                    // Share as text
                    Button {
                        shareList()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }

                    // Add manual item
                    Button {
                        showingAddItem = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .alert("Export fehlgeschlagen", isPresented: Binding(
                get: { exportError != nil },
                set: { if !$0 { exportError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(exportError ?? "")
            }
            .alert("Exportiert!", isPresented: $showingExportSuccess) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Die Einkaufsliste wurde in die Erinnerungen-App übertragen.")
            }
        }
        .sheet(isPresented: $showingAddItem) {
            AddManualItemView { name, amount, unit in
                let item = ShoppingItem(
                    name: name, amount: amount, unit: unit,
                    isManual: true, sortOrder: items.count
                )
                modelContext.insert(item)
            }
        }
    }

    private func regenerateFromPlan() {
        // Remove all auto-generated items, keep manual ones
        let autoItems = items.filter { !$0.isManual }
        for item in autoItems { modelContext.delete(item) }

        let generated = ShoppingListGenerator.generate(from: entriesThisWeek)
        let baseOrder = items.filter { $0.isManual }.count
        for (idx, item) in generated.enumerated() {
            item.sortOrder = baseOrder + idx
            modelContext.insert(item)
        }
    }

    private func exportToReminders() {
        isExporting = true
        Task {
            defer { isExporting = false }
            do {
                try await RemindersService.exportToReminders(items: unchecked)
                showingExportSuccess = true
            } catch {
                exportError = error.localizedDescription
            }
        }
    }

    private func shareList() {
        let text = unchecked.map { "• \($0.displayText)" }.joined(separator: "\n")
        guard !text.isEmpty else { return }
        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let vc = windowScene.windows.first?.rootViewController {
            vc.present(av, animated: true)
        }
    }
}

struct ShoppingItemRow: View {
    @Bindable var item: ShoppingItem

    var body: some View {
        HStack {
            Button {
                item.isChecked.toggle()
            } label: {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isChecked ? .green : .secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)

            Text(item.displayText)
                .strikethrough(item.isChecked, color: .secondary)
                .foregroundStyle(item.isChecked ? .secondary : .primary)

            if item.isManual {
                Spacer()
                Image(systemName: "pencil")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

struct AddManualItemView: View {
    @Environment(\.dismiss) private var dismiss
    let onAdd: (String, Double, String) -> Void

    @State private var name = ""
    @State private var amount = ""
    @State private var unit = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Zutat (z.B. Milch)", text: $name)
                    HStack {
                        TextField("Menge (z.B. 500)", text: $amount)
                            .keyboardType(.decimalPad)
                        TextField("Einheit (z.B. ml)", text: $unit)
                    }
                }
            }
            .navigationTitle("Eintrag hinzufügen")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Abbrechen") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Hinzufügen") {
                        let a = Double(amount.replacingOccurrences(of: ",", with: ".")) ?? 1
                        onAdd(name, a, unit)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
