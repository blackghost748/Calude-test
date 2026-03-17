import SwiftUI

struct WeekPlanView: View {
    @EnvironmentObject private var store: DataStore
    @State private var selectedWeekday: Int?
    @State private var showingPicker = false

    private let weekdays = [(1,"Montag"),(2,"Dienstag"),(3,"Mittwoch"),(4,"Donnerstag"),
                            (5,"Freitag"),(6,"Samstag"),(7,"Sonntag")]
    private var weekID: String { MealEntry.currentWeekID() }
    private var thisWeek: [MealEntry] { store.mealEntries.filter { $0.weekID == weekID } }

    var body: some View {
        NavigationView {
            Group {
                if thisWeek.isEmpty {
                    EmptyStateView(
                        title: "Noch nichts geplant",
                        systemImage: "calendar",
                        description: "Tippe auf + um ein Rezept einem Tag zuzuordnen."
                    )
                } else {
                    List {
                        weekdaysList
                    }
                }
            }
            .navigationTitle("Diese Woche")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        ForEach(weekdays, id: \.0) { day, label in
                            Button(label) {
                                selectedWeekday = day
                                showingPicker = true
                            }
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .sheet(isPresented: $showingPicker) {
            if let day = selectedWeekday {
                RecipePickerView(weekday: day, weekID: weekID)
            }
        }
    }

    private var weekdaysList: some View {
        ForEach(weekdays, id: \.0) { day, label in
            let entries = thisWeek.filter { $0.weekday == day }
            if !entries.isEmpty {
                Section(label) {
                    ForEach(entries) { entry in
                        MealEntryRow(entry: entry)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    store.deleteMealEntry(entry)
                                } label: {
                                    Label("Entfernen", systemImage: "trash")
                                }
                            }
                    }
                    Button {
                        selectedWeekday = day; showingPicker = true
                    } label: {
                        Label("Weiteres Rezept", systemImage: "plus.circle")
                            .foregroundColor(.blue).font(.subheadline)
                    }
                }
            }
        }
    }
}

struct MealEntryRow: View {
    @EnvironmentObject private var store: DataStore
    let entry: MealEntry

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(store.recipe(for: entry)?.name ?? "Gelöscht").font(.headline)
                if !entry.addedBy.isEmpty {
                    Text("von \(entry.addedBy)").font(.caption).foregroundColor(.secondary)
                }
            }
            Spacer()
            HStack(spacing: 4) {
                Button {
                    if entry.servings > 1 {
                        var e = entry; e.servings -= 1; store.updateMealEntry(e)
                    }
                } label: { Image(systemName: "minus.circle") }
                .buttonStyle(.plain).foregroundColor(.secondary)

                Text("\(entry.servings)")
                    .font(.subheadline.monospacedDigit())
                    .frame(minWidth: 20, alignment: .center)

                Button {
                    var e = entry; e.servings += 1; store.updateMealEntry(e)
                } label: { Image(systemName: "plus.circle") }
                .buttonStyle(.plain).foregroundColor(.secondary)

                Image(systemName: "person.2").foregroundColor(.secondary).font(.caption)
            }
        }
    }
}

struct RecipePickerView: View {
    @EnvironmentObject private var store: DataStore
    @Environment(\.dismiss) private var dismiss

    let weekday: Int
    let weekID: String

    @State private var servings = 4
    @State private var searchText = ""

    var filtered: [Recipe] {
        store.recipes
            .filter { searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }
            .sorted { $0.name < $1.name }
    }

    var body: some View {
        NavigationView {
            List(filtered) { recipe in
                Button {
                    let entry = MealEntry(weekday: weekday, weekID: weekID,
                                         recipeID: recipe.id, servings: servings)
                    store.addMealEntry(entry)
                    dismiss()
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(recipe.name).font(.headline).foregroundColor(.primary)
                            Text("Standard: \(recipe.defaultServings) Portionen")
                                .font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        if recipe.isFavorite {
                            Image(systemName: "star.fill").foregroundColor(.yellow).font(.caption)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Suchen")
            .navigationTitle("Rezept wählen")
            .safeAreaInset(edge: .bottom) {
                HStack {
                    Label("Portionen:", systemImage: "person.2")
                    Spacer()
                    Stepper("\(servings)", value: $servings, in: 1...20).fixedSize()
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
