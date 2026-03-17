import SwiftUI
import SwiftData

struct RecipeListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Recipe.name) private var recipes: [Recipe]

    @State private var showingAddRecipe = false
    @State private var showingImport = false
    @State private var searchText = ""
    @State private var showFavoritesOnly = false

    var filtered: [Recipe] {
        recipes.filter { recipe in
            let matchesSearch = searchText.isEmpty || recipe.name.localizedCaseInsensitiveContains(searchText)
            let matchesFavorite = !showFavoritesOnly || recipe.isFavorite
            return matchesSearch && matchesFavorite
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filtered) { recipe in
                    NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                        RecipeRowView(recipe: recipe)
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            recipe.isFavorite.toggle()
                        } label: {
                            Label(recipe.isFavorite ? "Kein Favorit" : "Favorit",
                                  systemImage: recipe.isFavorite ? "star.slash" : "star.fill")
                        }
                        .tint(.yellow)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            modelContext.delete(recipe)
                        } label: {
                            Label("Löschen", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle("Rezepte")
            .searchable(text: $searchText, prompt: "Rezept suchen")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showFavoritesOnly.toggle()
                    } label: {
                        Image(systemName: showFavoritesOnly ? "star.fill" : "star")
                            .foregroundStyle(showFavoritesOnly ? .yellow : .secondary)
                    }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        showingImport = true
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                    }
                    Button {
                        showingAddRecipe = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .overlay {
                if filtered.isEmpty {
                    ContentUnavailableView(
                        showFavoritesOnly ? "Keine Favoriten" : "Keine Rezepte",
                        systemImage: showFavoritesOnly ? "star" : "book.closed",
                        description: Text(showFavoritesOnly
                            ? "Markiere Rezepte als Favorit mit dem Stern-Symbol."
                            : "Tippe auf + um dein erstes Rezept anzulegen.")
                    )
                }
            }
        }
        .sheet(isPresented: $showingAddRecipe) {
            AddEditRecipeView()
        }
        .sheet(isPresented: $showingImport) {
            RecipeImportView()
        }
    }
}

struct RecipeRowView: View {
    let recipe: Recipe

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.name)
                    .font(.headline)
                HStack(spacing: 6) {
                    Label("\(recipe.defaultServings) Portionen", systemImage: "person.2")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if !recipe.tags.isEmpty {
                        Text(recipe.tags.prefix(2).joined(separator: " · "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Spacer()
            if recipe.isFavorite {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                    .font(.subheadline)
            }
        }
        .padding(.vertical, 2)
    }
}
