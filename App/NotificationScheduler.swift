import Foundation
import UserNotifications
import DoseCore

enum NotificationScheduler {
    static let takenActionID = "TAKEN"
    static let categoryID = "DOSE"

    /// Adds an "I took it" button to the notification itself.
    static let category = UNNotificationCategory(
        identifier: categoryID,
        actions: [UNNotificationAction(identifier: takenActionID, title: "I took it", options: [])],
        intentIdentifiers: []
    )

    static func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        case .denied:
            return false
        default:
            return true
        }
    }

    /// Replaces everything pending with the current plan, so recording a dose cancels its follow-ups.
    static func replaceAll(with plan: [PlannedReminder]) async {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        for reminder in plan {
            let content = UNMutableNotificationContent()
            content.categoryIdentifier = categoryID
            content.userInfo = ["dueAt": reminder.occurrence.dueAt.timeIntervalSince1970]
            content.sound = .default
            switch reminder.kind {
            case .gentle:
                content.title = "\(reminder.occurrence.slot.title) dose"
                content.body = "It's time for your \(reminder.occurrence.slot.title.lowercased()) dose."
            case .followUp:
                content.title = "Did you take your \(reminder.occurrence.slot.title.lowercased()) dose?"
                content.body = "Tap to open the app and confirm."
            }
            let parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: reminder.fireAt)
            let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
            try? await center.add(UNNotificationRequest(identifier: reminder.id, content: content, trigger: trigger))
        }
    }
}

/// Handles taps on a notification: the "I took it" button records the dose without opening the app.
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    weak var model: AppModel?

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        guard response.actionIdentifier == NotificationScheduler.takenActionID,
              let seconds = response.notification.request.content.userInfo["dueAt"] as? TimeInterval else { return }
        await MainActor.run { model?.markTaken(dueAt: Date(timeIntervalSince1970: seconds)) }
    }

    /// Show reminders even while the app is open.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
