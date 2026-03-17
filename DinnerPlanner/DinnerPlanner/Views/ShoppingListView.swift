import SwiftUI

struct ShoppingListView: View {
    @EnvironmentObject private var store: DataStore
    @State private var showingAddItem = false
    @State private var exportError: String?
    @State private var showingExportSuccess = false
    @State private var isExporting = false

    private var weekID: String { MealEntry.currentWeekID() }
    private var thisWeekEntries: [MealEntry] { store.mealEntries.filter { $0.weekID == weekID } }

    private var unchecked: [ShoppingItem] { store.shoppingItems.filter { !$0.isChecked } }
    private var checked:   [ShoppingItem] { store.shoppingItems.filter {  $0.isChecked  } }

    /// Unchecked items grouped by category in display order.
    private var groupedUnchecked: [(category: String, items: [ShoppingItem])] {
        let byCategory = Dictionary(grouping: unchecked) { $0.category }
        return IngredientCategorizer.allCategories.compactMap { cat in
            guard let items = byCategory[cat], !items.isEmpty else { return nil }
            return (cat, items.sorted { $0.name < $1.name })
        }
    }

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
                    shoppingList
                }
            }
            .navigationTitle("Einkaufsliste")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    toolbarButtons
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
                let category = IngredientCategorizer.category(for: name)
                store.addShoppingItem(ShoppingItem(
                    name: name, amount: amount, unit: unit,
                    isManual: true, sortOrder: store.shoppingItems.count,
                    category: category
                ))
            }
        }
    }

    @ViewBuilder private var toolbarButtons: some View {
        HStack(spacing: 16) {
            Button { regenerate() } label: { Image(systemName: "arrow.clockwise") }
            if isExporting {
                ProgressView()
            } else {
                Button { exportToReminders() } label: { Image(systemName: "checkmark.circle") }
            }
            Button { shareList() } label: { Image(systemName: "square.and.arrow.up") }
            Button { showingAddItem = true } label: { Image(systemName: "plus") }
        }
    }

    private var shoppingList: some View {
        List {
            ForEach(groupedUnchecked, id: \.category) { group in
                Section(group.category) {
                    ForEach(group.items) { item in
                        ShoppingItemRow(item: item)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    store.deleteShoppingItem(item)
                                } label: {
                                    Label("Löschen", systemImage: "trash")
                                }
                            }
                    }
                }
            }
            if !checked.isEmpty {
                checkedSection
            }
        }
    }

    private var checkedSection: some View {
        Section("Erledigt (\(checked.count))") {
            ForEach(checked.sorted { $0.name < $1.name }) { item in
                ShoppingItemRow(item: item)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            store.deleteShoppingItem(item)
                        } label: {
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

    private func regenerate() {
        let generated = ShoppingListGenerator.generate(from: thisWeekEntries, recipes: store.recipes)
        store.replaceAutoItems(with: generated)
    }

    private func exportToReminders() {
        isExporting = true
        Task { @MainActor in
            do {
                try await RemindersService.exportToReminders(items: unchecked)
                showingExportSuccess = true
            } catch {
                exportError = error.localizedDescription
            }
            isExporting = false
        }
    }

    private func shareList() {
        // Share grouped by category for readability
        var lines: [String] = []
        for group in groupedUnchecked {
            lines.append("── \(group.category) ──")
            lines.append(contentsOf: group.items.map { "• \($0.displayText)" })
        }
        guard !lines.isEmpty else { return }
        let text = lines.joined(separator: "\n")
        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let vc = windowScene.windows.first?.rootViewController {
            vc.present(av, animated: true)
        }
    }
}

// MARK: - Row

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
                Image(systemName: "pencil").font(.caption2).foregroundColor(Color.secondary.opacity(0.5))
            }
        }
    }
}

// MARK: - Manual add sheet

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
