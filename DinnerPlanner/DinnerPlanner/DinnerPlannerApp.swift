import SwiftUI
import SwiftData

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
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("ModelContainer konnte nicht erstellt werden: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
