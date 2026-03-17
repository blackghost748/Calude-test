import XCTest
@testable import DinnerPlanner

final class DinnerPlannerTests: XCTestCase {

    // MARK: - ShoppingListGenerator

    func testIngredientMerging() {
        let recipe = Recipe(
            name: "Test",
            defaultServings: 4,
            ingredients: [
                Ingredient(name: "Mehl",  amount: 200, unit: "g",     sortOrder: 0),
                Ingredient(name: "Eier",  amount: 2,   unit: "Stück", sortOrder: 1),
            ]
        )
        let entry1 = MealEntry(weekday: 1, weekID: "2024-W10", recipeID: recipe.id, servings: 4)
        let entry2 = MealEntry(weekday: 3, weekID: "2024-W10", recipeID: recipe.id, servings: 4)

        let items = ShoppingListGenerator.generate(from: [entry1, entry2], recipes: [recipe])

        XCTAssertEqual(items.count, 2)
        let mehl = items.first { $0.name.lowercased() == "mehl" }
        XCTAssertEqual(mehl?.amount, 400) // 200g × 2 entries
        XCTAssertEqual(mehl?.unit, "g")
    }

    func testServingsScaling() {
        let recipe = Recipe(
            name: "Pasta",
            defaultServings: 2,
            ingredients: [Ingredient(name: "Nudeln", amount: 100, unit: "g")]
        )
        let entry = MealEntry(weekday: 2, weekID: "2024-W10", recipeID: recipe.id, servings: 4)
        let items = ShoppingListGenerator.generate(from: [entry], recipes: [recipe])
        XCTAssertEqual(items.first?.amount, 200) // 100g / 2 × 4 = 200g
    }

    // MARK: - RecipeImportService

    func testIngredientLineParsing_withUnit() {
        let result = RecipeImportService.parseIngredientLine("200 g Mehl")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.amount, 200)
        XCTAssertEqual(result?.unit, "g")
        XCTAssertEqual(result?.name, "Mehl")
    }

    func testIngredientLineParsing_decimalComma() {
        let result = RecipeImportService.parseIngredientLine("1,5 kg Kartoffeln")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.amount, 1.5)
    }

    // MARK: - ShoppingItem

    func testDisplayText_withUnit() {
        let item = ShoppingItem(name: "Mehl", amount: 500, unit: "g")
        XCTAssertEqual(item.displayText, "500 g Mehl")
    }

    func testDisplayText_noUnit() {
        let item = ShoppingItem(name: "Salz", amount: 1, unit: "")
        XCTAssertEqual(item.displayText, "Salz")
    }

    // MARK: - MealEntry

    func testCurrentWeekIDFormat() {
        let weekID = MealEntry.currentWeekID()
        XCTAssertTrue(weekID.contains("-W"), "weekID should contain -W: \(weekID)")
        XCTAssertEqual(weekID.count, 8) // "2024-W10"
    }

    // MARK: - DataStore

    func testDataStoreAddAndDeleteRecipe() {
        let store = DataStore()
        let initialCount = store.recipes.count
        let recipe = Recipe(name: "Testrezept")
        store.addRecipe(recipe)
        XCTAssertEqual(store.recipes.count, initialCount + 1)
        store.deleteRecipe(recipe)
        XCTAssertEqual(store.recipes.count, initialCount)
    }

    func testToggleFavorite() {
        let store = DataStore()
        let recipe = Recipe(name: "Favorit-Test", isFavorite: false)
        store.addRecipe(recipe)
        store.toggleFavorite(recipe)
        XCTAssertTrue(store.recipes.first { $0.id == recipe.id }?.isFavorite == true)
        store.deleteRecipe(recipe)
    }
}
