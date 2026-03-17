import SwiftUI
import SwiftData
import CloudKit

@main
struct DinnerPlannerApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([
                Recipe.self,
                Ingredient.self,
                MealEntry.self,
                ShoppingItem.self,
                FamilyGroup.self,
            ])
            // CloudKit sync enabled via cloudKitDatabase option
            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic
            )
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("ModelContainer konnte nicht erstellt werden: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onContinueUserActivity(NSUserActivityTypes.viewShareActivity) { activity in
                    // Handle incoming CloudKit share URL
                    handleIncomingShare(activity: activity)
                }
        }
        .modelContainer(modelContainer)
    }

    private func handleIncomingShare(activity: NSUserActivity) {
        guard let metadata = activity.userInfo?[CKShareMetadataKey] as? CKShare.Metadata else { return }
        Task { @MainActor in
            let service = CloudKitSharingService()
            await service.acceptShare(metadata: metadata)
        }
    }
}

private enum NSUserActivityTypes {
    static let viewShareActivity = "CKShareMetadataKey"
}

private let CKShareMetadataKey = "CKShareMetadata"
