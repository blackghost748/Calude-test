import SwiftUI

struct RecipeListView: View {
    @EnvironmentObject private var store: DataStore
    @State private var showingAddRecipe = false
    @State private var showingImport = false
    @State private var searchText = ""
    @State private var showFavoritesOnly = false

    var filtered: [Recipe] {
        store.recipes
            .filter {
                let matchesSearch = searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText)
                let matchesFav = !showFavoritesOnly || $0.isFavorite
                return matchesSearch && matchesFav
            }
            .sorted { $0.name < $1.name }
    }

    var body: some View {
        NavigationView {
            Group {
                if filtered.isEmpty {
                    EmptyStateView(
                        title: showFavoritesOnly ? "Keine Favoriten" : "Keine Rezepte",
                        systemImage: showFavoritesOnly ? "star" : "book.closed",
                        description: showFavoritesOnly
                            ? "Markiere Rezepte als Favorit mit dem Stern-Symbol."
                            : "Tippe auf + um dein erstes Rezept anzulegen."
                    )
                } else {
                    List {
                        ForEach(filtered) { recipe in
                            NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                                RecipeRowView(recipe: recipe)
                            }
                            .swipeActions(edge: .leading) {
                                Button { store.toggleFavorite(recipe) } label: {
                                    Label(recipe.isFavorite ? "Kein Favorit" : "Favorit",
                                          systemImage: recipe.isFavorite ? "star.slash" : "star.fill")
                                }
                                .tint(.yellow)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    store.deleteRecipe(recipe)
                                } label: {
                                    Label("Löschen", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .searchable(text: $searchText, prompt: "Rezept suchen")
                }
            }
            .navigationTitle("Rezepte")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showFavoritesOnly.toggle()
                    } label: {
                        Image(systemName: showFavoritesOnly ? "star.fill" : "star")
                            .foregroundColor(showFavoritesOnly ? .yellow : .secondary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button { showingImport = true } label: {
                            Image(systemName: "square.and.arrow.down")
                        }
                        Button { showingAddRecipe = true } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
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
                Text(recipe.name).font(.headline)
                HStack(spacing: 6) {
                    Label("\(recipe.defaultServings) Portionen", systemImage: "person.2")
                        .font(.caption).foregroundColor(.secondary)
                    if !recipe.tags.isEmpty {
                        Text(recipe.tags.prefix(2).joined(separator: " · "))
                            .font(.caption).foregroundColor(.secondary)
                    }
                }
            }
            Spacer()
            if recipe.isFavorite {
                Image(systemName: "star.fill").foregroundColor(.yellow).font(.subheadline)
            }
        }
        .padding(.vertical, 2)
    }
}
