import Foundation

public enum ReminderKind: Equatable {
    /// One gentle reminder when the dose is due.
    case gentle
    /// Repeated reminders after that, until the dose is recorded.
    case followUp
}

public struct PlannedReminder: Equatable, Identifiable {
    public let id: String
    public let occurrence: Occurrence
    public let fireAt: Date
    public let kind: ReminderKind
}

public enum ReminderPlanner {
    /// iOS keeps at most 64 pending local notifications.
    public static let maxPending = 64

    /// Plans a few days ahead and re-plans whenever the app opens or a dose is recorded. If there are
    /// more than iOS allows, the soonest ones are kept and the rest are planned on the next re-plan.
    public static func plan(log: DoseLog, now: Date, calendar: Calendar, days: Int = 3) -> [PlannedReminder] {
        guard let horizon = calendar.date(byAdding: .day, value: days, to: now) else { return [] }
        let schedule = log.schedule
        var result: [PlannedReminder] = []
        for occ in schedule.occurrences(from: max(log.trackingStart, now.addingTimeInterval(-86_400)), through: horizon, calendar: calendar) {
            if log.entry(for: occ) != nil { continue }
            let key = "\(occ.reminderID.uuidString.prefix(8))-\(Int(occ.dueAt.timeIntervalSince1970))"
            if occ.dueAt > now {
                result.append(PlannedReminder(id: "dose-\(key)-0", occurrence: occ, fireAt: occ.dueAt, kind: .gentle))
            }
            for n in 1...max(schedule.followUpCount, 1) where schedule.followUpCount > 0 {
                let fire = occ.dueAt.addingTimeInterval(TimeInterval(n * schedule.followUpMinutes * 60))
                if fire > now {
                    result.append(PlannedReminder(id: "dose-\(key)-\(n)", occurrence: occ, fireAt: fire, kind: .followUp))
                }
            }
        }
        return Array(result.sorted { $0.fireAt < $1.fireAt }.prefix(maxPending))
    }
}
