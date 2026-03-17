import SwiftUI

struct ShoppingListView: View {
    @EnvironmentObject private var store: DataStore
    @State private var showingAddItem = false
    @State private var exportError: String?
    @State private var showingExportSuccess = false
    @State private var isExporting = false

    private var weekID: String { MealEntry.currentWeekID() }
    private var thisWeekEntries: [MealEntry] { store.mealEntries.filter { $0.weekID == weekID } }
    private var unchecked: [ShoppingItem] { store.shoppingItems.filter { !$0.isChecked }.sorted { $0.sortOrder < $1.sortOrder } }
    private var checked:   [ShoppingItem] { store.shoppingItems.filter {  $0.isChecked }.sorted { $0.sortOrder < $1.sortOrder } }

    var body: some View {
        NavigationView {
            Group {
                if store.shoppingItems.isEmpty {
                    EmptyStateView(
                        title: "Keine Einträge",
                        systemImage: "cart",
                        description: "Tippe auf ↺ um die Liste aus dem Wochenplan zu generieren."
                    )
                } else {
                    List {
                        if !unchecked.isEmpty {
                            Section("Noch kaufen (\(unchecked.count))") {
                                ForEach(unchecked) { item in
                                    ShoppingItemRow(item: item)
                                        .swipeActions(edge: .trailing) {
                                            Button(role: .destructive) { store.deleteShoppingItem(item) } label: {
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
                                            Button(role: .destructive) { store.deleteShoppingItem(item) } label: {
                                                Label("Löschen", systemImage: "trash")
                                            }
                                        }
                                }
                                Button(role: .destructive) {
                                    checked.forEach { store.deleteShoppingItem($0) }
                                } label: {
                                    Label("Alle erledigten löschen", systemImage: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Einkaufsliste")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button { regenerate() } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                        if isExporting { ProgressView() } else {
                            Button { exportToReminders() } label: {
                                Image(systemName: "checkmark.circle")
                            }
                        }
                        Button { shareList() } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                        Button { showingAddItem = true } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .alert("Export fehlgeschlagen", isPresented: Binding(
                get: { exportError != nil },
                set: { if !$0 { exportError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: { Text(exportError ?? "") }
            .alert("Exportiert!", isPresented: $showingExportSuccess) {
                Button("OK", role: .cancel) {}
            } message: { Text("Die Liste wurde in die Erinnerungen-App übertragen.") }
        }
        .navigationViewStyle(.stack)
        .sheet(isPresented: $showingAddItem) {
            AddManualItemView { name, amount, unit in
                store.addShoppingItem(ShoppingItem(
                    name: name, amount: amount, unit: unit,
                    isManual: true, sortOrder: store.shoppingItems.count
                ))
            }
        }
    }

    private func regenerate() {
        let generated = ShoppingListGenerator.generate(from: thisWeekEntries, recipes: store.recipes)
        store.replaceAutoItems(with: generated)
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
    @EnvironmentObject private var store: DataStore
    let item: ShoppingItem

    var body: some View {
        HStack {
            Button {
                var updated = item
                updated.isChecked.toggle()
                store.updateShoppingItem(updated)
            } label: {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(item.isChecked ? .green : .secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)

            Text(item.displayText)
                .strikethrough(item.isChecked, color: .secondary)
                .foregroundColor(item.isChecked ? .secondary : .primary)

            if item.isManual {
                Spacer()
                Image(systemName: "pencil").font(.caption2).foregroundColor(.secondary)
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
        NavigationView {
            Form {
                Section {
                    TextField("Zutat (z.B. Milch)", text: $name)
                    HStack {
                        TextField("Menge (z.B. 500)", text: $amount).keyboardType(.decimalPad)
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
                    .disabled(name.isEmpty).fontWeight(.semibold)
                }
            }
        }
    }
}
