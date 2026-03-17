import Foundation
import SwiftData

/// Stores metadata about the CloudKit sharing group.
/// There should only ever be one instance (the group this device belongs to).
@Model
final class FamilyGroup {
    var id: UUID
    var name: String
    var createdAt: Date
    /// Serialised CKShare.URL as string – stored after sharing is created.
    var shareURLString: String?
    /// iCloud record name of the share owner.
    var ownerRecordName: String?

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
    }
}
