import Foundation

struct Ingredient: Identifiable, Codable {
    var id: UUID
    var name: String
    var amount: Double
    var unit: String
    var sortOrder: Int

    init(id: UUID = UUID(), name: String, amount: Double, unit: String, sortOrder: Int = 0) {
        self.id = id
        self.name = name
        self.amount = amount
        self.unit = unit
        self.sortOrder = sortOrder
    }

    func scaledAmount(targetServings: Int, defaultServings: Int) -> Double {
        guard defaultServings > 0 else { return amount }
        return amount * Double(targetServings) / Double(defaultServings)
    }
}
