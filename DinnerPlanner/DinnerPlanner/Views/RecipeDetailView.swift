import SwiftUI
import SwiftData

struct RecipeDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var recipe: Recipe

    @State private var showingEdit = false
    @State private var servings: Int

    init(recipe: Recipe) {
        self.recipe = recipe
        _servings = State(initialValue: recipe.defaultServings)
    }

    var body: some View {
        List {
            Section("Zutaten für \(servings) Portionen") {
                Stepper("Portionen: \(servings)", value: $servings, in: 1...20)
                    .font(.subheadline)

                ForEach(recipe.ingredients.sorted(by: { $0.sortOrder < $1.sortOrder })) { ingredient in
                    HStack {
                        Text(ingredient.name)
                        Spacer()
                        let scaled = ingredient.scaledAmount(
                            targetServings: servings,
                            defaultServings: recipe.defaultServings
                        )
                        let formatted = scaled.truncatingRemainder(dividingBy: 1) == 0
                            ? String(Int(scaled))
                            : String(format: "%.1f", scaled)
                        Text("\(formatted) \(ingredient.unit)")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if let url = recipe.sourceURL, !url.isEmpty {
                Section {
                    Link("Originalrezept öffnen", destination: URL(string: url) ?? URL(string: "https://example.com")!)
                        .font(.subheadline)
                }
            }

            if !recipe.tags.isEmpty {
                Section("Tags") {
                    TagCloudView(tags: recipe.tags)
                }
            }
        }
        .navigationTitle(recipe.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button {
                        recipe.isFavorite.toggle()
                    } label: {
                        Image(systemName: recipe.isFavorite ? "star.fill" : "star")
                            .foregroundStyle(recipe.isFavorite ? .yellow : .secondary)
                    }
                    Button("Bearbeiten") {
                        showingEdit = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            AddEditRecipeView(recipe: recipe)
        }
    }
}

struct TagCloudView: View {
    let tags: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.blue.opacity(0.15), in: Capsule())
                        .foregroundStyle(.blue)
                }
            }
        }
    }
}
