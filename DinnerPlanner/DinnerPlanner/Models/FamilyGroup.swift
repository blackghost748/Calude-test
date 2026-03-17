import Foundation

// Placeholder – Familien-Kollaboration erfordert einen bezahlten Apple Developer Account.
struct FamilyGroup: Identifiable, Codable {
    var id: UUID
    var name: String
    var createdAt: Date

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
        self.createdAt = Date()
    }
}
