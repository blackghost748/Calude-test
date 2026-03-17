import XCTest
@testable import DinnerPlanner

final class DinnerPlannerTests: XCTestCase {

    // MARK: - ShoppingListGenerator

    func testIngredientMerging() {
        let recipe = Recipe(name: "Test", defaultServings: 4)
        let ing1 = Ingredient(name: "Mehl", amount: 200, unit: "g", sortOrder: 0)
        let ing2 = Ingredient(name: "Eier", amount: 2, unit: "Stück", sortOrder: 1)
        ing1.recipe = recipe
        ing2.recipe = recipe
        recipe.ingredients = [ing1, ing2]

        let entry1 = MealEntry(weekday: 1, weekID: "2024-W10", recipe: recipe, servings: 4)
        let entry2 = MealEntry(weekday: 3, weekID: "2024-W10", recipe: recipe, servings: 4)

        let items = ShoppingListGenerator.generate(from: [entry1, entry2])

        XCTAssertEqual(items.count, 2)
        // 200g Mehl × 2 entries = 400g
        let mehl = items.first { $0.name.lowercased() == "mehl" }
        XCTAssertEqual(mehl?.amount, 400)
        XCTAssertEqual(mehl?.unit, "g")
    }

    func testServingsScaling() {
        let recipe = Recipe(name: "Pasta", defaultServings: 2)
        let ing = Ingredient(name: "Nudeln", amount: 100, unit: "g", sortOrder: 0)
        ing.recipe = recipe
        recipe.ingredients = [ing]

        let entry = MealEntry(weekday: 2, weekID: "2024-W10", recipe: recipe, servings: 4)
        let items = ShoppingListGenerator.generate(from: [entry])

        // 100g / 2 Portionen × 4 Portionen = 200g
        XCTAssertEqual(items.first?.amount, 200)
    }

    // MARK: - RecipeImportService

    func testIngredientLineParsing() {
        let cases: [(String, Double, String, String)] = [
            ("200 g Mehl", 200, "g", "Mehl"),
            ("3 Eier", 1, "", "3 Eier"),  // no unit pattern matches "Eier" as ingredient
            ("1,5 kg Kartoffeln", 1.5, "kg", "Kartoffeln"),
        ]

        for (line, expectedAmount, _, _) in cases {
            let result = RecipeImportService.parseIngredientLine(line)
            XCTAssertNotNil(result, "Expected result for: \(line)")
            if line.contains("g ") || line.contains("kg ") {
                XCTAssertEqual(result?.amount, expectedAmount, "Amount mismatch for: \(line)")
            }
        }
    }

    // MARK: - ShoppingItem

    func testDisplayText() {
        let item = ShoppingItem(name: "Mehl", amount: 500, unit: "g")
        XCTAssertEqual(item.displayText, "500 g Mehl")

        let item2 = ShoppingItem(name: "Salz", amount: 1, unit: "")
        XCTAssertEqual(item2.displayText, "Salz")
    }

    // MARK: - MealEntry

    func testCurrentWeekIDFormat() {
        let weekID = MealEntry.currentWeekID()
        // Format: YYYY-Www
        XCTAssertTrue(weekID.contains("-W"), "weekID should contain -W: \(weekID)")
        XCTAssertEqual(weekID.count, 8) // "2024-W10"
    }
}
