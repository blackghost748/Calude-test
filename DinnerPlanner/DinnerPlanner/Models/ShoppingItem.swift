import Foundation

struct ShoppingItem: Identifiable, Codable {
    var id: UUID
    var name: String
    var amount: Double
    var unit: String
    var isChecked: Bool
    var isManual: Bool
    var sortOrder: Int

    init(id: UUID = UUID(), name: String, amount: Double, unit: String,
         isManual: Bool = false, sortOrder: Int = 0) {
        self.id = id
        self.name = name
        self.amount = amount
        self.unit = unit
        self.isChecked = false
        self.isManual = isManual
        self.sortOrder = sortOrder
    }

    var displayText: String {
        let fmt = amount.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(amount))
            : String(format: "%.1f", amount)
        if unit.isEmpty { return name }
        return "\(fmt) \(unit) \(name)"
    }
}
