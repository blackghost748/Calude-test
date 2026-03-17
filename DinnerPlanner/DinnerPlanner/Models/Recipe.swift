import Foundation

struct Recipe: Identifiable, Codable {
    var id: UUID
    var name: String
    var isFavorite: Bool
    var tags: [String]
    var defaultServings: Int
    var sourceURL: String?
    var createdAt: Date
    var modifiedAt: Date
    var ingredients: [Ingredient]

    init(
        id: UUID = UUID(),
        name: String,
        defaultServings: Int = 4,
        isFavorite: Bool = false,
        tags: [String] = [],
        sourceURL: String? = nil,
        ingredients: [Ingredient] = []
    ) {
        self.id = id
        self.name = name
        self.defaultServings = defaultServings
        self.isFavorite = isFavorite
        self.tags = tags
        self.sourceURL = sourceURL
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.ingredients = ingredients
    }
}
