import Foundation
import Combine

final class DataStore: ObservableObject {
    @Published var recipes: [Recipe] = []
    @Published var mealEntries: [MealEntry] = []
    @Published var shoppingItems: [ShoppingItem] = []

    private let recipesURL    = DataStore.fileURL("recipes.json")
    private let entriesURL    = DataStore.fileURL("mealEntries.json")
    private let shoppingURL   = DataStore.fileURL("shoppingItems.json")

    init() { load() }

    // MARK: - Recipe CRUD

    func addRecipe(_ recipe: Recipe) {
        recipes.append(recipe)
        save()
    }

    func updateRecipe(_ recipe: Recipe) {
        guard let idx = recipes.firstIndex(where: { $0.id == recipe.id }) else { return }
        recipes[idx] = recipe
        save()
    }

    func deleteRecipe(_ recipe: Recipe) {
        recipes.removeAll { $0.id == recipe.id }
        mealEntries.removeAll { $0.recipeID == recipe.id }
        save()
    }

    func toggleFavorite(_ recipe: Recipe) {
        guard let idx = recipes.firstIndex(where: { $0.id == recipe.id }) else { return }
        recipes[idx].isFavorite.toggle()
        save()
    }

    // MARK: - MealEntry CRUD

    func addMealEntry(_ entry: MealEntry) {
        mealEntries.append(entry)
        save()
    }

    func updateMealEntry(_ entry: MealEntry) {
        guard let idx = mealEntries.firstIndex(where: { $0.id == entry.id }) else { return }
        mealEntries[idx] = entry
        save()
    }

    func deleteMealEntry(_ entry: MealEntry) {
        mealEntries.removeAll { $0.id == entry.id }
        save()
    }

    func recipe(for entry: MealEntry) -> Recipe? {
        recipes.first { $0.id == entry.recipeID }
    }

    // MARK: - ShoppingItem CRUD

    func addShoppingItem(_ item: ShoppingItem) {
        shoppingItems.append(item)
        save()
    }

    func updateShoppingItem(_ item: ShoppingItem) {
        guard let idx = shoppingItems.firstIndex(where: { $0.id == item.id }) else { return }
        shoppingItems[idx] = item
        save()
    }

    func deleteShoppingItem(_ item: ShoppingItem) {
        shoppingItems.removeAll { $0.id == item.id }
        save()
    }

    func replaceAutoItems(with newItems: [ShoppingItem]) {
        shoppingItems.removeAll { !$0.isManual }
        shoppingItems.append(contentsOf: newItems)
        // Re-sort: manual items first, then auto
        shoppingItems = shoppingItems.enumerated().map { idx, item in
            var i = item; i.sortOrder = idx; return i
        }
        save()
    }

    // MARK: - Persistence

    private func load() {
        recipes      = load(from: recipesURL)  ?? []
        mealEntries  = load(from: entriesURL)  ?? []
        shoppingItems = load(from: shoppingURL) ?? []
    }

    func save() {
        save(recipes,      to: recipesURL)
        save(mealEntries,  to: entriesURL)
        save(shoppingItems, to: shoppingURL)
    }

    private func load<T: Decodable>(from url: URL) -> T? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private func save<T: Encodable>(_ value: T, to url: URL) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        try? data.write(to: url, options: .atomic)
    }

    private static func fileURL(_ name: String) -> URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(name)
    }
}
