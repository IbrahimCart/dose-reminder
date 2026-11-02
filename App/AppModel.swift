import Foundation
import UIKit
import DoseCore

/// Holds the log, saves it after every change, and keeps the phone's reminders in step with it.
@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var log: DoseLog
    @Published private(set) var now = Date()
    @Published var notificationsAllowed = true
    /// Set while confetti is on screen; the root view draws it over everything.
    @Published private(set) var confettiID: UUID?

    let calendar = Calendar.current
    private let store: JSONFileStore
    private var timer: Timer?

    init(store: JSONFileStore = .standard()) {
        self.store = store
        self.log = store.load() ?? DoseLog(trackingStart: Date())
        // Keep "now" fresh so a dose flips from "due" to "missed" while the app is open.
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.now = Date() }
        }
        Task { await refreshPermission(); await reschedule() }
    }

    func refresh() {
        now = Date()
        Task { await refreshPermission(); await reschedule() }
    }

    func status(_ occ: Occurrence) -> DoseStatus { log.status(of: occ, now: now) }
    func canMarkTaken(_ occ: Occurrence) -> Bool { log.canMarkTaken(occ, now: now) }
    var today: [Occurrence] { log.today(now: now, calendar: calendar) }
    var history: [Occurrence] { log.history(now: now, calendar: calendar) }
    var lastMissedOrLate: Occurrence? { log.lastMissedOrLate(now: now, calendar: calendar) }
    var report: String { Report.text(log: log, now: now, calendar: calendar) }

    func markTaken(_ occ: Occurrence) {
        log.markTaken(occ, at: Date())
        commit()
    }

    /// Used by the "Taken" button on a notification.
    func markTaken(reminderID: UUID, dueAt: Date) {
        let due = log.schedule.occurrences(from: dueAt, through: dueAt, calendar: calendar)
        guard let occ = due.first(where: { $0.reminderID == reminderID }) else { return }
        markTaken(occ)
    }

    /// A buzz and a burst of confetti over the whole screen. With Reduce Motion on, only the buzz.
    func celebrate() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        let id = UUID()
        confettiID = id
        Task {
            try? await Task.sleep(for: .seconds(ConfettiView.duration))
            if confettiID == id { confettiID = nil }
        }
    }

    func undoTaken(_ occ: Occurrence) {
        log.undoTaken(occ)
        commit()
    }

    func changeSchedule(_ schedule: Schedule) {
        log.changeSchedule(schedule, now: Date())
        commit()
    }

    /// Replaces the reminder with the same id, or adds it if it is new and there is still room.
    func saveReminder(_ reminder: Reminder) {
        var schedule = log.schedule
        if let index = schedule.reminders.firstIndex(where: { $0.id == reminder.id }) {
            schedule.reminders[index] = reminder
        } else if schedule.reminders.count < Schedule.maxReminders {
            schedule.reminders.append(reminder)
        }
        changeSchedule(schedule)
    }

    func deleteReminder(id: UUID) {
        var schedule = log.schedule
        schedule.reminders.removeAll { $0.id == id }
        changeSchedule(schedule)
    }

    func addSeizure(note: String) {
        log.addSeizure(at: Date(), note: note)
        commit()
    }

    func removeSeizure(_ note: SeizureNote) {
        log.removeSeizure(note)
        commit()
    }

    private func commit() {
        now = Date()
        try? store.save(log)
        Task { await reschedule() }
    }

    private func refreshPermission() async {
        notificationsAllowed = await NotificationScheduler.requestPermission()
    }

    private func reschedule() async {
        await NotificationScheduler.replaceAll(with: ReminderPlanner.plan(log: log, now: Date(), calendar: calendar))
    }
}
