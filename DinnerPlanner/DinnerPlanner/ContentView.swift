import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            RecipeListView()
                .tabItem {
                    Label("Rezepte", systemImage: "book.closed")
                }

            WeekPlanView()
                .tabItem {
                    Label("Wochenplan", systemImage: "calendar")
                }

            ShoppingListView()
                .tabItem {
                    Label("Einkauf", systemImage: "cart")
                }

            SettingsView()
                .tabItem {
                    Label("Einstellungen", systemImage: "gear")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Recipe.self, Ingredient.self, MealEntry.self, ShoppingItem.self, FamilyGroup.self],
                        inMemory: true)
}
