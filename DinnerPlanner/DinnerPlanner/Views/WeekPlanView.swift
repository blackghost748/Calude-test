import SwiftUI

struct WeekPlanView: View {
    @EnvironmentObject private var store: DataStore
    @State private var selectedWeekday: Int?
    @State private var showingPicker = false
    @Environment(\.horizontalSizeClass) private var hSizeClass

    private let weekdays = [(1,"Mo","Montag"),(2,"Di","Dienstag"),(3,"Mi","Mittwoch"),
                            (4,"Do","Donnerstag"),(5,"Fr","Freitag"),(6,"Sa","Samstag"),
                            (7,"So","Sonntag")]
    private var weekID: String { MealEntry.currentWeekID() }
    private var weekLabel: String {
        let cal = Calendar(identifier: .iso8601)
        let parts = weekID.split(separator: "-")
        if parts.count == 2, let week = Int(parts[1].dropFirst()) {
            let fmt = DateFormatter()
            fmt.dateFormat = "dd.MM."
            if let monday = cal.date(from: DateComponents(
                weekOfYear: week,
                yearForWeekOfYear: Int(parts[0]) ?? 2024,
                weekday: 2
            )) {
                let sunday = cal.date(byAdding: .day, value: 6, to: monday)!
                return "\(fmt.string(from: monday))–\(fmt.string(from: sunday))"
            }
        }
        return weekID
    }

    var body: some View {
        NavigationView {
            Group {
                if hSizeClass == .regular {
                    weekGrid
                } else {
                    weekList
                }
            }
            .navigationTitle("KW \(weekID.split(separator: "-").last?.dropFirst() ?? "?")  ·  \(weekLabel)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        ForEach(weekdays, id: \.0) { day, short, label in
                            Button(label) { selectedWeekday = day; showingPicker = true }
                        }
                    } label: { Image(systemName: "plus") }
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

    // MARK: - Portrait: scrollable list, all 7 days always visible

    private var weekList: some View {
        List {
            ForEach(weekdays, id: \.0) { day, _, label in
                Section {
                    let entries = entriesFor(day)
                    if entries.isEmpty {
                        emptyDayRow(day: day)
                    } else {
                        ForEach(entries) { entry in
                            MealEntryRow(entry: entry)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        store.deleteMealEntry(entry)
                                    } label: { Label("Entfernen", systemImage: "trash") }
                                }
                        }
                        addButton(day: day)
                    }
                } header: {
                    dayHeader(short: label, day: day)
                }
            }
        }
    }

    // MARK: - Landscape: 7-column grid

    private var weekGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7),
                spacing: 8
            ) {
                ForEach(weekdays, id: \.0) { day, short, label in
                    VStack(spacing: 0) {
                        // Day header
                        Text(short)
                            .font(.caption.bold())
                            .foregroundColor(isToday(day) ? .white : .secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(isToday(day) ? Color.accentColor : Color.clear)
                            .cornerRadius(8, corners: [.topLeft, .topRight])

                        Divider()

                        // Meal cards
                        VStack(spacing: 6) {
                            let entries = entriesFor(day)
                            if entries.isEmpty {
                                Text("Nichts\ngeplant")
                                    .font(.caption2)
                                    .foregroundColor(Color.secondary.opacity(0.6))
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity, minHeight: 44)
                            } else {
                                ForEach(entries) { entry in
                                    gridMealCard(entry: entry)
                                }
                            }
                            Button {
                                selectedWeekday = day; showingPicker = true
                            } label: {
                                Image(systemName: "plus.circle")
                                    .foregroundColor(.accentColor)
                                    .font(.title3)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(6)
                        .frame(maxWidth: .infinity, minHeight: 80, alignment: .top)
                    }
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(8)
                }
            }
            .padding()
        }
    }

    // MARK: - Helpers

    private func entriesFor(_ day: Int) -> [MealEntry] {
        store.mealEntries.filter { $0.weekID == weekID && $0.weekday == day }
    }

    private func isToday(_ weekday: Int) -> Bool {
        let cal = Calendar(identifier: .iso8601)
        return cal.component(.weekday, from: Date()) == (weekday % 7) + 1
    }

    private func emptyDayRow(day: Int) -> some View {
        Button {
            selectedWeekday = day; showingPicker = true
        } label: {
            HStack {
                Image(systemName: "plus.circle")
                    .foregroundColor(.accentColor)
                Text("Rezept hinzufügen")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            }
        }
    }

    private func addButton(day: Int) -> some View {
        Button {
            selectedWeekday = day; showingPicker = true
        } label: {
            Label("Weiteres Rezept", systemImage: "plus.circle")
                .foregroundColor(.accentColor)
                .font(.subheadline)
        }
    }

    private func dayHeader(short: String, day: Int) -> some View {
        HStack {
            Text(short)
                .font(.headline)
                .foregroundColor(isToday(day) ? .accentColor : .primary)
            if isToday(day) {
                Text("Heute")
                    .font(.caption)
                    .foregroundColor(.accentColor)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Color.accentColor.opacity(0.15))
                    .cornerRadius(4)
            }
        }
    }

    private func gridMealCard(entry: MealEntry) -> some View {
        let name = store.recipe(for: entry)?.name ?? "?"
        return Text(name)
            .font(.caption2)
            .lineLimit(2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(4)
            .background(Color.accentColor.opacity(0.12))
            .cornerRadius(4)
            .contextMenu {
                Button(role: .destructive) {
                    store.deleteMealEntry(entry)
                } label: { Label("Entfernen", systemImage: "trash") }
            }
    }
}

// MARK: - Corner radius helper

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

private struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners,
                                cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// MARK: - MealEntryRow (portrait list)

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
                    if entry.servings > 1 { var e = entry; e.servings -= 1; store.updateMealEntry(e) }
                } label: { Image(systemName: "minus.circle") }
                .buttonStyle(.plain).foregroundColor(.secondary)

                Text("\(entry.servings)").font(.subheadline.monospacedDigit()).frame(minWidth: 20)

                Button {
                    var e = entry; e.servings += 1; store.updateMealEntry(e)
                } label: { Image(systemName: "plus.circle") }
                .buttonStyle(.plain).foregroundColor(.secondary)

                Image(systemName: "person.2").foregroundColor(.secondary).font(.caption)
            }
        }
    }
}

// MARK: - RecipePickerView

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
                    store.addMealEntry(MealEntry(weekday: weekday, weekID: weekID,
                                                 recipeID: recipe.id, servings: servings))
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
