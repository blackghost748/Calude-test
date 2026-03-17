import Foundation
import SwiftData

@Model
final class Ingredient {
    var id: UUID
    var name: String
    var amount: Double
    var unit: String
    var sortOrder: Int

    var recipe: Recipe?

    init(name: String, amount: Double, unit: String, sortOrder: Int = 0) {
        self.id = UUID()
        self.name = name
        self.amount = amount
        self.unit = unit
        self.sortOrder = sortOrder
    }

    /// Returns amount scaled to targetServings relative to the recipe's defaultServings.
    func scaledAmount(targetServings: Int, defaultServings: Int) -> Double {
        guard defaultServings > 0 else { return amount }
        return amount * Double(targetServings) / Double(defaultServings)
    }
}
