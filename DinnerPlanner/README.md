# Dinner Planner

iOS-App für gemeinsame Abendessen-Planung in der Familie.

## Features

- **Rezeptverwaltung** – Rezepte anlegen, per URL oder Text importieren, Favoriten markieren
- **Wochenplan** – Rezepte Mo–So zuordnen, Portionen pro Tag anpassen
- **Einkaufsliste** – automatisch aus dem Wochenplan generieren, Zutaten mergen, in Erinnerungen exportieren
- **Familien-Kollaboration** – Echtzeit-Sync über iCloud/CloudKit, Einladung per QR-Code

## Technologie

| Schicht | Technologie |
|---------|-------------|
| UI | SwiftUI |
| Datenpersistenz | SwiftData |
| Cloud-Sync | CloudKit (NSPersistentCloudKitContainer) |
| Sharing | CKShare + QR-Code |
| iOS-Integration | EventKit / Reminders API |

## Voraussetzungen

- Xcode 15+
- iOS 17+ Deployment Target
- Aktiver Apple Developer Account (für CloudKit)

## Setup

1. Projekt in Xcode öffnen: `DinnerPlanner.xcodeproj`
2. **Signing & Capabilities** konfigurieren:
   - Development Team auswählen
   - Bundle ID anpassen (`com.dinnerplanner.app` → eigene ID)
   - Capability **iCloud** hinzufügen → CloudKit aktivieren
   - Container `iCloud.com.dinnerplanner.app` anlegen (oder an eigene Bundle ID anpassen)
   - Capability **Push Notifications** hinzufügen (benötigt für CloudKit-Live-Updates)
3. Auf echtem Gerät mit iCloud-Account bauen und starten

## Kollaboration (Familien-Gruppe)

1. App starten → Tab **Einstellungen**
2. **Neue Gruppe erstellen** → Namen vergeben
3. **Gruppe mit Familie teilen** antippen → CloudKit-Share wird erstellt
4. **QR-Code anzeigen** oder Einladungslink per iMessage/WhatsApp senden
5. Familienmitglied öffnet den Link → wird automatisch zur Gruppe hinzugefügt
6. Alle Änderungen synchronisieren in Echtzeit

## Projektstruktur

```
DinnerPlanner/
├── Models/
│   ├── Recipe.swift          – Rezept (SwiftData + CloudKit)
│   ├── Ingredient.swift      – Zutat mit Mengen-Skalierung
│   ├── MealEntry.swift       – Geplante Mahlzeit pro Wochentag
│   ├── ShoppingItem.swift    – Einkaufslisteneintrag
│   └── FamilyGroup.swift     – Familien-Gruppe (CloudKit Share Metadata)
├── Views/
│   ├── RecipeListView.swift  – Rezeptliste mit Suche & Favoriten-Filter
│   ├── RecipeDetailView.swift – Detailansicht mit Portionen-Skalierung
│   ├── AddEditRecipeView.swift – Rezept anlegen / bearbeiten
│   ├── RecipeImportView.swift – URL- und Text-Import
│   ├── WeekPlanView.swift    – Wochenübersicht Mo–So
│   ├── ShoppingListView.swift – Einkaufsliste mit Export
│   └── SettingsView.swift    – Gruppen-Verwaltung, QR-Code
├── Services/
│   ├── RecipeImportService.swift     – JSON-LD Parser & Text-Parser
│   ├── CloudKitSharingService.swift  – CKShare erstellen & QR-Code
│   ├── RemindersService.swift        – Export in iOS Erinnerungen
│   └── ShoppingListGenerator.swift  – Zutaten mergen & skalieren
├── DinnerPlannerApp.swift    – App Entry Point, ModelContainer
└── ContentView.swift         – Tab-Navigation
```
