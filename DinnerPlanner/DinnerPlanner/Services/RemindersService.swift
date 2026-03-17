import Foundation
import EventKit

/// Exports shopping items to the iOS Reminders app.
struct RemindersService {

    static func exportToReminders(items: [ShoppingItem], listName: String = "Einkaufsliste") async throws {
        let store = EKEventStore()

        // Request access
        if #available(iOS 17.0, *) {
            try await store.requestFullAccessToReminders()
        } else {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                store.requestAccess(to: .reminder) { granted, error in
                    if let error { continuation.resume(throwing: error); return }
                    if !granted { continuation.resume(throwing: RemindersError.accessDenied); return }
                    continuation.resume()
                }
            }
        }

        // Find or create the list (EKCalendar)
        let calendars = store.calendars(for: .reminder)
        let calendar: EKCalendar
        if let existing = calendars.first(where: { $0.title == listName }) {
            calendar = existing
        } else {
            let newList = EKCalendar(for: .reminder, eventStore: store)
            newList.title = listName
            newList.source = store.defaultCalendarForNewReminders()?.source
            try store.saveCalendar(newList, commit: true)
            calendar = newList
        }

        // Add unchecked items as reminders
        for item in items where !item.isChecked {
            let reminder = EKReminder(eventStore: store)
            reminder.title = item.displayText
            reminder.calendar = calendar
            try store.save(reminder, commit: false)
        }
        try store.commit()
    }
}

enum RemindersError: LocalizedError {
    case accessDenied

    var errorDescription: String? {
        "Zugriff auf Erinnerungen wurde verweigert. Bitte in den Einstellungen erlauben."
    }
}
