import Foundation

struct MealEntry: Identifiable, Codable {
    var id: UUID
    var weekday: Int       // 1 = Monday … 7 = Sunday
    var weekID: String     // e.g. "2024-W12"
    var servings: Int
    var addedBy: String
    var recipeID: UUID

    init(id: UUID = UUID(), weekday: Int, weekID: String, recipeID: UUID,
         servings: Int, addedBy: String = "") {
        self.id = id
        self.weekday = weekday
        self.weekID = weekID
        self.recipeID = recipeID
        self.servings = servings
        self.addedBy = addedBy
    }

    static func currentWeekID() -> String {
        weekID(offsetWeeks: 0)
    }

    static func weekID(offsetWeeks: Int) -> String {
        let cal = Calendar(identifier: .iso8601)
        let date = cal.date(byAdding: .weekOfYear, value: offsetWeeks, to: Date()) ?? Date()
        let components = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        let year = components.yearForWeekOfYear ?? 2024
        let week = components.weekOfYear ?? 1
        return String(format: "%04d-W%02d", year, week)
    }
}
