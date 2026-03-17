import Foundation
import SwiftData

/// Represents one planned meal on a specific weekday.
@Model
final class MealEntry {
    var id: UUID
    /// Weekday as ISO weekday number (1 = Monday … 7 = Sunday, matching .iso8601)
    var weekday: Int
    /// ISO year+week identifier, e.g. "2024-W12", so each week is independent.
    var weekID: String
    var servings: Int
    var addedBy: String   // iCloud display name of the user who added this entry

    var recipe: Recipe?

    init(weekday: Int, weekID: String, recipe: Recipe, servings: Int, addedBy: String = "") {
        self.id = UUID()
        self.weekday = weekday
        self.weekID = weekID
        self.recipe = recipe
        self.servings = servings
        self.addedBy = addedBy
    }

    static func currentWeekID() -> String {
        let cal = Calendar(identifier: .iso8601)
        let components = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        let year = components.yearForWeekOfYear ?? 2024
        let week = components.weekOfYear ?? 1
        return String(format: "%04d-W%02d", year, week)
    }
}
