import SwiftUI

struct AddEditRecipeView: View {
    @EnvironmentObject private var store: DataStore
    @Environment(\.dismiss) private var dismiss

    var recipe: Recipe?

    @State private var name = ""
    @State private var defaultServings = 4
    @State private var isFavorite = false
    @State private var tagsText = ""
    @State private var sourceURL = ""
    @State private var ingredients: [DraftIngredient] = []
    @State private var newName = ""
    @State private var newAmount = ""
    @State private var newUnit = ""

    var isEditing: Bool { recipe != nil }

    var body: some View {
        NavigationView {
            Form {
                Section("Rezeptname") {
                    TextField("z.B. Spaghetti Bolognese", text: $name)
                    Stepper("Portionen: \(defaultServings)", value: $defaultServings, in: 1...20)
                    Toggle("Favorit", isOn: $isFavorite)
                }
                Section("Tags (Komma-getrennt)") {
                    TextField("z.B. vegetarisch, schnell", text: $tagsText)
                }
                Section("Quell-URL (optional)") {
                    TextField("https://...", text: $sourceURL)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                }
                Section("Zutaten") {
                    ForEach($ingredients) { $item in
                        HStack {
                            TextField("Zutat", text: $item.name)
                            TextField("Menge", text: $item.amount)
                                .frame(width: 60).keyboardType(.decimalPad)
                            TextField("Einheit", text: $item.unit)
                                .frame(width: 60)
                        }
                    }
                    .onDelete { ingredients.remove(atOffsets: $0) }
                    .onMove  { ingredients.move(fromOffsets: $0, toOffset: $1) }

                    HStack {
                        TextField("Neue Zutat", text: $newName)
                        TextField("Menge", text: $newAmount)
                            .frame(width: 60).keyboardType(.decimalPad)
                        TextField("Einheit", text: $newUnit).frame(width: 60)
                        Button { addIngredient() } label: {
                            Image(systemName: "plus.circle.fill").foregroundColor(.green)
                        }
                        .disabled(newName.isEmpty)
                    }
                }
            }
            .navigationTitle(isEditing ? "Rezept bearbeiten" : "Neues Rezept")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Speichern") { save() }
                        .disabled(name.isEmpty)
                        .fontWeight(.semibold)
                }
            }
        }
        .onAppear { populateIfEditing() }
    }

    private func populateIfEditing() {
        guard let recipe else { return }
        name = recipe.name
        defaultServings = recipe.defaultServings
        isFavorite = recipe.isFavorite
        tagsText = recipe.tags.joined(separator: ", ")
        sourceURL = recipe.sourceURL ?? ""
        ingredients = recipe.ingredients.sorted { $0.sortOrder < $1.sortOrder }.map {
            DraftIngredient(name: $0.name, amount: formatAmt($0.amount), unit: $0.unit)
        }
    }

    private func addIngredient() {
        ingredients.append(DraftIngredient(name: newName, amount: newAmount, unit: newUnit))
        newName = ""; newAmount = ""; newUnit = ""
    }

    private func save() {
        let tags = tagsText.components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        let builtIngredients = ingredients.enumerated().compactMap { idx, d -> Ingredient? in
            guard !d.name.isEmpty else { return nil }
            let amt = Double(d.amount.replacingOccurrences(of: ",", with: ".")) ?? 1.0
            return Ingredient(name: d.name, amount: amt, unit: d.unit, sortOrder: idx)
        }
        if var existing = recipe {
            existing.name = name
            existing.defaultServings = defaultServings
            existing.isFavorite = isFavorite
            existing.tags = tags
            existing.sourceURL = sourceURL.isEmpty ? nil : sourceURL
            existing.modifiedAt = Date()
            existing.ingredients = builtIngredients
            store.updateRecipe(existing)
        } else {
            let r = Recipe(name: name, defaultServings: defaultServings,
                           isFavorite: isFavorite, tags: tags,
                           sourceURL: sourceURL.isEmpty ? nil : sourceURL,
                           ingredients: builtIngredients)
            store.addRecipe(r)
        }
        dismiss()
    }

    private func formatAmt(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(v)) : String(format: "%.1f", v)
    }
}

struct DraftIngredient: Identifiable {
    var id = UUID()
    var name: String
    var amount: String
    var unit: String
}
