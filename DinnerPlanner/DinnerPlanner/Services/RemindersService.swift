import Foundation
import EventKit

struct RemindersService {

    static func exportToReminders(items: [ShoppingItem], listName: String = "Einkaufsliste") async throws {
        let store = EKEventStore()

        // Use completion-based API – compatible with iOS 16
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            store.requestAccess(to: .reminder) { granted, error in
                if let error { continuation.resume(throwing: error); return }
                guard granted else { continuation.resume(throwing: RemindersError.accessDenied); return }
                continuation.resume()
            }
        }

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
        "Zugriff auf Erinnerungen verweigert. Bitte in den Einstellungen erlauben."
    }
}
