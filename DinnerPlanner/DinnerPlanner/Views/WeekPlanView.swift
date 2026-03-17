import SwiftUI
import SwiftData

struct WeekPlanView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allEntries: [MealEntry]
    @Query(sort: \Recipe.name) private var recipes: [Recipe]

    @State private var selectedWeekday: Int? = nil
    @State private var showingRecipePicker = false

    private let weekdays = [
        (1, "Montag"), (2, "Dienstag"), (3, "Mittwoch"), (4, "Donnerstag"),
        (5, "Freitag"), (6, "Samstag"), (7, "Sonntag")
    ]

    private var currentWeekID: String { MealEntry.currentWeekID() }

    private var entriesThisWeek: [MealEntry] {
        allEntries.filter { $0.weekID == currentWeekID }
    }

    private func entries(for weekday: Int) -> [MealEntry] {
        entriesThisWeek.filter { $0.weekday == weekday }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(weekdays, id: \.0) { (day, label) in
                    Section(label) {
                        ForEach(entries(for: day)) { entry in
                            MealEntryRow(entry: entry)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        modelContext.delete(entry)
                                    } label: {
                                        Label("Entfernen", systemImage: "trash")
                                    }
                                }
                        }

                        Button {
                            selectedWeekday = day
                            showingRecipePicker = true
                        } label: {
                            Label("Rezept hinzufügen", systemImage: "plus.circle")
                                .foregroundStyle(.blue)
                                .font(.subheadline)
                        }
                    }
                }
            }
            .navigationTitle("Diese Woche")
            .navigationBarTitleDisplayMode(.large)
            .overlay {
                if entriesThisWeek.isEmpty {
                    ContentUnavailableView(
                        "Noch keine Mahlzeiten geplant",
                        systemImage: "calendar",
                        description: Text("Tippe auf + um ein Rezept einem Tag zuzuordnen.")
                    )
                }
            }
        }
        .sheet(isPresented: $showingRecipePicker) {
            if let weekday = selectedWeekday {
                RecipePickerView(weekday: weekday, weekID: currentWeekID)
            }
        }
    }
}

struct MealEntryRow: View {
    @Bindable var entry: MealEntry

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.recipe?.name ?? "Gelöscht")
                    .font(.headline)
                if !entry.addedBy.isEmpty {
                    Text("von \(entry.addedBy)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            HStack(spacing: 4) {
                Button {
                    if entry.servings > 1 { entry.servings -= 1 }
                } label: {
                    Image(systemName: "minus.circle")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                Text("\(entry.servings)")
                    .font(.subheadline.monospacedDigit())
                    .frame(minWidth: 20, alignment: .center)

                Button {
                    entry.servings += 1
                } label: {
                    Image(systemName: "plus.circle")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                Image(systemName: "person.2")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        }
    }
}

struct RecipePickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Recipe.name) private var recipes: [Recipe]

    let weekday: Int
    let weekID: String

    @State private var servings: Int = 4
    @State private var searchText = ""

    var filtered: [Recipe] {
        recipes.filter { searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            List(filtered) { recipe in
                Button {
                    let entry = MealEntry(weekday: weekday, weekID: weekID, recipe: recipe, servings: servings)
                    modelContext.insert(entry)
                    dismiss()
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(recipe.name).font(.headline).foregroundStyle(.primary)
                            Text("\(recipe.defaultServings) Portionen Standardmäßig").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if recipe.isFavorite {
                            Image(systemName: "star.fill").foregroundStyle(.yellow).font(.caption)
                        }
                    }
                }
            }
            .navigationTitle("Rezept wählen")
            .searchable(text: $searchText, prompt: "Suchen")
            .safeAreaInset(edge: .bottom) {
                HStack {
                    Label("Portionen:", systemImage: "person.2")
                    Spacer()
                    Stepper("\(servings)", value: $servings, in: 1...20)
                        .fixedSize()
                }
                .padding()
                .background(.bar)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") { dismiss() }
                }
            }
        }
    }
}
