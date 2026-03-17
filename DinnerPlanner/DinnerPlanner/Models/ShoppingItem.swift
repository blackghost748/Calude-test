import Foundation
import SwiftData

@Model
final class ShoppingItem {
    var id: UUID
    var name: String
    var amount: Double
    var unit: String
    var isChecked: Bool
    var isManual: Bool   // manually added by user (not generated from meal plan)
    var sortOrder: Int

    init(name: String, amount: Double, unit: String, isManual: Bool = false, sortOrder: Int = 0) {
        self.id = UUID()
        self.name = name
        self.amount = amount
        self.unit = unit
        self.isChecked = false
        self.isManual = isManual
        self.sortOrder = sortOrder
    }

    /// Display string, e.g. "500 g Mehl" or "3 Stück Eier"
    var displayText: String {
        let formattedAmount = amount.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(amount))
            : String(format: "%.1f", amount)
        if unit.isEmpty { return name }
        return "\(formattedAmount) \(unit) \(name)"
    }
}
