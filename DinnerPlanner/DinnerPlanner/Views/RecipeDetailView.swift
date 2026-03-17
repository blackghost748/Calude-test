import SwiftUI

struct RecipeDetailView: View {
    @EnvironmentObject private var store: DataStore
    let recipe: Recipe

    @State private var servings: Int
    @State private var showingEdit = false

    // Use fresh copy from store so edits are reflected
    private var current: Recipe {
        store.recipes.first { $0.id == recipe.id } ?? recipe
    }

    init(recipe: Recipe) {
        self.recipe = recipe
        _servings = State(initialValue: recipe.defaultServings)
    }

    var body: some View {
        List {
            Section("Zutaten für \(servings) Portionen") {
                Stepper("Portionen: \(servings)", value: $servings, in: 1...20)
                    .font(.subheadline)

                ForEach(current.ingredients.sorted { $0.sortOrder < $1.sortOrder }) { ingredient in
                    HStack {
                        Text(ingredient.name)
                        Spacer()
                        let scaled = ingredient.scaledAmount(
                            targetServings: servings,
                            defaultServings: current.defaultServings
                        )
                        let fmt = scaled.truncatingRemainder(dividingBy: 1) == 0
                            ? String(Int(scaled)) : String(format: "%.1f", scaled)
                        Text("\(fmt) \(ingredient.unit)").foregroundColor(.secondary)
                    }
                }
            }

            if let url = current.sourceURL, !url.isEmpty,
               let link = URL(string: url) {
                Section {
                    Link("Originalrezept öffnen", destination: link).font(.subheadline)
                }
            }

            if !current.tags.isEmpty {
                Section("Tags") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(current.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 10).padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.15))
                                    .foregroundColor(.blue)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(current.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button {
                        store.toggleFavorite(current)
                    } label: {
                        Image(systemName: current.isFavorite ? "star.fill" : "star")
                            .foregroundColor(current.isFavorite ? .yellow : .secondary)
                    }
                    Button("Bearbeiten") { showingEdit = true }
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            AddEditRecipeView(recipe: current)
        }
    }
}
