import Foundation

struct ShoppingListGenerator {

    struct MergeKey: Hashable {
        let name: String
        let unit: String
    }

    static func generate(from entries: [MealEntry], recipes: [Recipe]) -> [ShoppingItem] {
        var totals: [MergeKey: Double] = [:]
        var order: [MergeKey] = []

        for entry in entries {
            guard let recipe = recipes.first(where: { $0.id == entry.recipeID }) else { continue }
            for ingredient in recipe.ingredients.sorted(by: { $0.sortOrder < $1.sortOrder }) {
                let scaled = ingredient.scaledAmount(
                    targetServings: entry.servings,
                    defaultServings: recipe.defaultServings
                )
                let key = MergeKey(
                    name: ingredient.name.trimmingCharacters(in: .whitespaces).lowercased(),
                    unit: ingredient.unit.lowercased()
                )
                if totals[key] == nil { order.append(key) }
                totals[key, default: 0] += scaled
            }
        }

        return order.enumerated().compactMap { idx, key -> ShoppingItem? in
            guard let total = totals[key] else { return nil }
            let displayName = key.name.prefix(1).uppercased() + key.name.dropFirst()
            return ShoppingItem(name: displayName, amount: total, unit: key.unit, sortOrder: idx)
        }
    }
}
