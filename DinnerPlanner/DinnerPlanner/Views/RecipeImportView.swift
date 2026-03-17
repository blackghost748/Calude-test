import SwiftUI

struct RecipeImportView: View {
    @EnvironmentObject private var store: DataStore
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTab: ImportTab = .url
    @State private var urlText = ""
    @State private var pasteText = ""
    @State private var recipeName = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var importResult: RecipeImportResult?

    enum ImportTab: String, CaseIterable { case url = "URL"; case paste = "Text einfügen" }

    var body: some View {
        NavigationView {
            Form {
                Picker("Methode", selection: $selectedTab) {
                    ForEach(ImportTab.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)

                if selectedTab == .url {
                    Section("Rezept-URL") {
                        TextField("https://www.chefkoch.de/...", text: $urlText)
                            .keyboardType(.URL).autocapitalization(.none)
                        Text("Unterstützt Seiten mit strukturierten Rezeptdaten (JSON-LD).")
                            .font(.caption).foregroundColor(.secondary)
                    }
                } else {
                    Section("Rezeptname") {
                        TextField("z.B. Omas Gulasch", text: $recipeName)
                    }
                    Section("Zutaten einfügen (eine pro Zeile)") {
                        TextEditor(text: $pasteText).frame(minHeight: 150)
                        Text("Beispiel:\n200 g Mehl\n3 Eier\n100 ml Milch")
                            .font(.caption).foregroundColor(.secondary)
                    }
                }

                if let error = errorMessage {
                    Section {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .foregroundColor(.orange).font(.subheadline)
                    }
                }
            }
            .navigationTitle("Rezept importieren")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isLoading { ProgressView() } else {
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
        errorMessage = nil; isLoading = true
        Task { @MainActor in
            do {
                importResult = selectedTab == .url
                    ? try await RecipeImportService.importFromURL(urlText)
                    : RecipeImportService.importFromText(pasteText, recipeName: recipeName)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    private func saveResult(_ result: RecipeImportResult) {
        let ingredients = result.ingredients.enumerated().map { idx, raw in
            Ingredient(name: raw.name, amount: raw.amount, unit: raw.unit, sortOrder: idx)
        }
        store.addRecipe(Recipe(name: result.name, defaultServings: result.defaultServings,
                               ingredients: ingredients))
    }
}

extension RecipeImportResult: Identifiable { public var id: String { name } }

struct ImportPreviewView: View {
    let result: RecipeImportResult
    let onDone: (Bool) -> Void

    var body: some View {
        NavigationView {
            List {
                Section("Rezept") {
                    Text(result.name).font(.headline)
                    Text("\(result.defaultServings) Portionen").foregroundColor(.secondary)
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
                    Button("Übernehmen") { onDone(true) }.fontWeight(.semibold)
                }
            }
        }
    }
}
