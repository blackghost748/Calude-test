import SwiftUI
import SwiftData

struct RecipeImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTab: ImportTab = .url
    @State private var urlText: String = ""
    @State private var pasteText: String = ""
    @State private var recipeName: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var importResult: RecipeImportResult?
    @State private var showingPreview = false

    enum ImportTab: String, CaseIterable {
        case url = "URL"
        case paste = "Text einfügen"
    }

    var body: some View {
        NavigationStack {
            Form {
                Picker("Import-Methode", selection: $selectedTab) {
                    ForEach(ImportTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listRowInsets(.init())
                .padding(.vertical, 8)

                if selectedTab == .url {
                    Section("Rezept-URL") {
                        TextField("https://www.chefkoch.de/...", text: $urlText)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                        Text("Unterstützt Seiten mit strukturierten Rezeptdaten (z.B. Chefkoch, AllRecipes).")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Section("Rezeptname") {
                        TextField("z.B. Omas Gulasch", text: $recipeName)
                    }
                    Section("Zutaten einfügen (eine pro Zeile)") {
                        TextEditor(text: $pasteText)
                            .frame(minHeight: 150)
                        Text("Beispiel:\n200 g Mehl\n3 Eier\n100 ml Milch")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if let error = errorMessage {
                    Section {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                            .font(.subheadline)
                    }
                }
            }
            .navigationTitle("Rezept importieren")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Button("Importieren") { runImport() }
                            .fontWeight(.semibold)
                            .disabled(importButtonDisabled)
                    }
                }
            }
        }
        .sheet(item: $importResult) { result in
            ImportPreviewView(result: result) { confirmed in
                if confirmed { saveResult(result) }
                dismiss()
            }
        }
    }

    private var importButtonDisabled: Bool {
        selectedTab == .url ? urlText.isEmpty : (pasteText.isEmpty || recipeName.isEmpty)
    }

    private func runImport() {
        errorMessage = nil
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                if selectedTab == .url {
                    let result = try await RecipeImportService.importFromURL(urlText)
                    importResult = result
                } else {
                    let result = RecipeImportService.importFromText(pasteText, recipeName: recipeName)
                    importResult = result
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func saveResult(_ result: RecipeImportResult) {
        let recipe = Recipe(name: result.name, defaultServings: result.defaultServings)
        modelContext.insert(recipe)
        for (idx, raw) in result.ingredients.enumerated() {
            let ing = Ingredient(name: raw.name, amount: raw.amount, unit: raw.unit, sortOrder: idx)
            ing.recipe = recipe
            recipe.ingredients.append(ing)
            modelContext.insert(ing)
        }
    }
}

extension RecipeImportResult: Identifiable {
    public var id: String { name }
}

struct ImportPreviewView: View {
    let result: RecipeImportResult
    let onDone: (Bool) -> Void

    var body: some View {
        NavigationStack {
            List {
                Section("Rezept") {
                    Text(result.name).font(.headline)
                    Text("\(result.defaultServings) Portionen").foregroundStyle(.secondary)
                }
                Section("Erkannte Zutaten (\(result.ingredients.count))") {
                    ForEach(result.ingredients, id: \.name) { ing in
                        let amt = ing.amount.truncatingRemainder(dividingBy: 1) == 0
                            ? String(Int(ing.amount)) : String(format: "%.1f", ing.amount)
                        Text("\(amt) \(ing.unit) \(ing.name)")
                    }
                }
            }
            .navigationTitle("Vorschau")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Verwerfen") { onDone(false) }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Übernehmen") { onDone(true) }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}
