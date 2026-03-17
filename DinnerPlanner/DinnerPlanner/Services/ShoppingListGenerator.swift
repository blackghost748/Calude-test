import Foundation

struct ShoppingListGenerator {

    private struct MergeKey: Hashable {
        let normalizedName: String
        let unit: String
    }

    static func generate(from entries: [MealEntry], recipes: [Recipe]) -> [ShoppingItem] {
        var totals: [MergeKey: Double] = [:]
        // Keep the first display name seen for each key (capitalised original)
        var displayNames: [MergeKey: String] = [:]
        var order: [MergeKey] = []

        for entry in entries {
            guard let recipe = recipes.first(where: { $0.id == entry.recipeID }) else { continue }
            for ingredient in recipe.ingredients.sorted(by: { $0.sortOrder < $1.sortOrder }) {
                let scaled = ingredient.scaledAmount(
                    targetServings: entry.servings,
                    defaultServings: recipe.defaultServings
                )
                let normalized = IngredientCategorizer.normalize(ingredient.name)
                let key = MergeKey(normalizedName: normalized, unit: ingredient.unit.lowercased())

                if totals[key] == nil {
                    order.append(key)
                    // Capitalise display name
                    let display = ingredient.name.trimmingCharacters(in: .whitespaces)
                    displayNames[key] = display.prefix(1).uppercased() + display.dropFirst()
                }
                totals[key, default: 0] += scaled
            }
        }

        return order.enumerated().compactMap { idx, key -> ShoppingItem? in
            guard let total = totals[key], let displayName = displayNames[key] else { return nil }
            let category = IngredientCategorizer.category(for: key.normalizedName)
            return ShoppingItem(
                name: displayName,
                amount: total,
                unit: key.unit,
                sortOrder: idx,
                category: category
            )
        }
    }
}
