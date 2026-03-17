import Foundation
import SwiftData

@Model
final class Recipe {
    var id: UUID
    var name: String
    var isFavorite: Bool
    var tags: [String]
    var defaultServings: Int
    var sourceURL: String?
    var createdAt: Date
    var modifiedAt: Date

    @Relationship(deleteRule: .cascade)
    var ingredients: [Ingredient]

    init(
        name: String,
        defaultServings: Int = 4,
        isFavorite: Bool = false,
        tags: [String] = [],
        sourceURL: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.defaultServings = defaultServings
        self.isFavorite = isFavorite
        self.tags = tags
        self.sourceURL = sourceURL
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.ingredients = []
    }
}
