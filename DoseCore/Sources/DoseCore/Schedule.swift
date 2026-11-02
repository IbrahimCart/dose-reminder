import Foundation

public struct DoseTime: Codable, Equatable, Hashable {
    public var hour: Int
    public var minute: Int

    public init(hour: Int, minute: Int) {
        self.hour = hour
        self.minute = minute
    }
}

/// One daily reminder the person has set up. The label is whatever they type; the app never suggests one.
public struct Reminder: Codable, Equatable, Hashable, Identifiable {
    public var id: UUID
    public var title: String
    public var time: DoseTime
    public var isEnabled: Bool

    public init(id: UUID = UUID(), title: String, time: DoseTime, isEnabled: Bool = true) {
        self.id = id
        self.title = title
        self.time = time
        self.isEnabled = isEnabled
    }
}

/// One scheduled dose: a reminder on a particular day. Two occurrences are the same dose when the
/// reminder and the time match, so renaming a reminder never splits its history.
public struct Occurrence: Identifiable {
    public let reminderID: UUID
    public let title: String
    public let dueAt: Date
    public var id: String { "\(reminderID.uuidString)-\(Int(dueAt.timeIntervalSince1970))" }

    public init(reminderID: UUID, title: String, dueAt: Date) {
        self.reminderID = reminderID
        self.title = title
        self.dueAt = dueAt
    }
}

extension Occurrence: Hashable {
    public static func == (a: Occurrence, b: Occurrence) -> Bool {
        a.reminderID == b.reminderID && a.dueAt == b.dueAt
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(reminderID)
        hasher.combine(dueAt)
    }
}

public struct Schedule: Codable, Equatable {
    /// iOS keeps at most 64 pending notifications, and every reminder needs several of them.
    public static let maxReminders = 8

    // Fixed ids so two untouched default schedules are equal.
    static let morningID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    static let eveningID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!

    /// Starts with a morning and an evening reminder; the person can change, remove or add to them.
    public var reminders: [Reminder] = [
        Reminder(id: Schedule.morningID, title: "Morning", time: DoseTime(hour: 8, minute: 0)),
        Reminder(id: Schedule.eveningID, title: "Evening", time: DoseTime(hour: 20, minute: 0)),
    ]
    /// A dose not recorded within this long after it is due counts as missed.
    public var graceMinutes = 120
    /// "I took it" opens this long before the dose is due.
    public var earlyMinutes = 60
    /// After the first gentle reminder, how often to repeat until the dose is recorded.
    public var followUpMinutes = 15
    public var followUpCount = 8

    public init() {}

    /// Every enabled reminder due on `day`, earliest first.
    public func occurrences(on day: Date, calendar: Calendar) -> [Occurrence] {
        reminders.filter(\.isEnabled).compactMap { reminder in
            calendar.date(bySettingHour: reminder.time.hour, minute: reminder.time.minute, second: 0, of: day)
                .map { Occurrence(reminderID: reminder.id, title: reminder.title, dueAt: $0) }
        }
        .sorted { ($0.dueAt, $0.title) < ($1.dueAt, $1.title) }
    }

    /// Every scheduled dose with `start <= dueAt <= end`, oldest first.
    public func occurrences(from start: Date, through end: Date, calendar: Calendar) -> [Occurrence] {
        var result: [Occurrence] = []
        var day = calendar.startOfDay(for: start)
        while day <= end {
            result += occurrences(on: day, calendar: calendar).filter { $0.dueAt >= start && $0.dueAt <= end }
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return result.sorted { ($0.dueAt, $0.title) < ($1.dueAt, $1.title) }
    }

    /// True when only labels differ, so a rename does not need to restart tracking.
    func differsOnlyInTitles(from other: Schedule) -> Bool {
        func stripped(_ s: Schedule) -> Schedule {
            var copy = s
            copy.reminders = s.reminders.map { var r = $0; r.title = ""; return r }
            return copy
        }
        return stripped(self) == stripped(other)
    }
}
