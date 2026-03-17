import Foundation

struct ShoppingItem: Identifiable, Codable {
    var id: UUID
    var name: String
    var amount: Double
    var unit: String
    var isChecked: Bool
    var isManual: Bool
    var sortOrder: Int
    var category: String

    init(id: UUID = UUID(), name: String, amount: Double, unit: String,
         isManual: Bool = false, sortOrder: Int = 0, category: String = "Sonstiges") {
        self.id = id
        self.name = name
        self.amount = amount
        self.unit = unit
        self.isChecked = false
        self.isManual = isManual
        self.sortOrder = sortOrder
        self.category = category
    }

    // Custom decoder: category may be absent in older JSON files
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id        = try c.decode(UUID.self,   forKey: .id)
        name      = try c.decode(String.self, forKey: .name)
        amount    = try c.decode(Double.self, forKey: .amount)
        unit      = try c.decode(String.self, forKey: .unit)
        isChecked = try c.decode(Bool.self,   forKey: .isChecked)
        isManual  = try c.decode(Bool.self,   forKey: .isManual)
        sortOrder = try c.decode(Int.self,    forKey: .sortOrder)
        category  = try c.decodeIfPresent(String.self, forKey: .category) ?? "Sonstiges"
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, amount, unit, isChecked, isManual, sortOrder, category
    }

    var displayText: String {
        let fmt = amount.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(amount)) : String(format: "%.1f", amount)
        if unit.isEmpty { return name }
        return "\(fmt) \(unit) \(name)"
    }
}
