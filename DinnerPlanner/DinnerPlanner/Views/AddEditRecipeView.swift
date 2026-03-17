import SwiftUI
import SwiftData

struct AddEditRecipeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var recipe: Recipe?

    @State private var name: String = ""
    @State private var defaultServings: Int = 4
    @State private var isFavorite: Bool = false
    @State private var tagsText: String = ""
    @State private var sourceURL: String = ""
    @State private var ingredients: [DraftIngredient] = []

    @State private var newIngredientName = ""
    @State private var newIngredientAmount = ""
    @State private var newIngredientUnit = ""

    var isEditing: Bool { recipe != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Rezeptname") {
                    TextField("z.B. Spaghetti Bolognese", text: $name)
                    Stepper("Portionen: \(defaultServings)", value: $defaultServings, in: 1...20)
                    Toggle("Favorit", isOn: $isFavorite)
                }

                Section("Tags (Komma-getrennt)") {
                    TextField("z.B. vegetarisch, schnell, Pasta", text: $tagsText)
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
                                .frame(width: 60)
                                .keyboardType(.decimalPad)
                            TextField("Einheit", text: $item.unit)
                                .frame(width: 60)
                        }
                    }
                    .onDelete { ingredients.remove(atOffsets: $0) }
                    .onMove { ingredients.move(fromOffsets: $0, toOffset: $1) }

                    HStack {
                        TextField("Neue Zutat", text: $newIngredientName)
                        TextField("Menge", text: $newIngredientAmount)
                            .frame(width: 60)
                            .keyboardType(.decimalPad)
                        TextField("Einheit", text: $newIngredientUnit)
                            .frame(width: 60)
                        Button {
                            addIngredient()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.green)
                        }
                        .disabled(newIngredientName.isEmpty)
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
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Fertig") {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                            to: nil, from: nil, for: nil)
                        }
                    }
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
        ingredients = recipe.ingredients.sorted(by: { $0.sortOrder < $1.sortOrder }).map {
            DraftIngredient(name: $0.name, amount: formatAmount($0.amount), unit: $0.unit)
        }
    }

    private func addIngredient() {
        ingredients.append(DraftIngredient(
            name: newIngredientName,
            amount: newIngredientAmount,
            unit: newIngredientUnit
        ))
        newIngredientName = ""
        newIngredientAmount = ""
        newIngredientUnit = ""
    }

    private func save() {
        let tags = tagsText
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        if let recipe {
            recipe.name = name
            recipe.defaultServings = defaultServings
            recipe.isFavorite = isFavorite
            recipe.tags = tags
            recipe.sourceURL = sourceURL.isEmpty ? nil : sourceURL
            recipe.modifiedAt = Date()
            // Remove old ingredients
            for ing in recipe.ingredients { modelContext.delete(ing) }
            recipe.ingredients = []
            saveIngredients(to: recipe)
        } else {
            let newRecipe = Recipe(
                name: name,
                defaultServings: defaultServings,
                isFavorite: isFavorite,
                tags: tags,
                sourceURL: sourceURL.isEmpty ? nil : sourceURL
            )
            modelContext.insert(newRecipe)
            saveIngredients(to: newRecipe)
        }
        dismiss()
    }

    private func saveIngredients(to recipe: Recipe) {
        for (idx, draft) in ingredients.enumerated() {
            guard !draft.name.isEmpty else { continue }
            let amount = Double(draft.amount.replacingOccurrences(of: ",", with: ".")) ?? 1.0
            let ing = Ingredient(name: draft.name, amount: amount, unit: draft.unit, sortOrder: idx)
            ing.recipe = recipe
            recipe.ingredients.append(ing)
            modelContext.insert(ing)
        }
    }

    private func formatAmount(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(value)) : String(format: "%.1f", value)
    }
}

struct DraftIngredient: Identifiable {
    var id = UUID()
    var name: String
    var amount: String
    var unit: String
}
