import Foundation

public struct TakenEntry: Codable, Equatable, Identifiable {
    public var slot: DoseSlot
    public var dueAt: Date
    public var takenAt: Date
    public var id: Date { dueAt }

    public init(slot: DoseSlot, dueAt: Date, takenAt: Date) {
        self.slot = slot
        self.dueAt = dueAt
        self.takenAt = takenAt
    }
}

public struct SeizureNote: Codable, Equatable, Identifiable {
    public var id: UUID
    public var at: Date
    public var note: String

    public init(id: UUID = UUID(), at: Date, note: String) {
        self.id = id
        self.at = at
        self.note = note
    }
}

public enum DoseStatus: Equatable {
    case upcoming
    /// Due now (or overdue but still inside the grace window) and not yet recorded.
    case due
    case taken(at: Date)
    /// Recorded, but after the grace window had passed.
    case takenLate(at: Date)
    /// Grace window passed and nothing recorded.
    case missed
}

/// Everything the app remembers. It stores times only, never medication names.
public struct DoseLog: Codable, Equatable {
    public private(set) var schedule: Schedule
    /// Doses due before this are ignored, so installing the app never creates "missed" doses from the past.
    public private(set) var trackingStart: Date
    public private(set) var taken: [TakenEntry] = []
    public private(set) var seizures: [SeizureNote] = []

    public init(schedule: Schedule = Schedule(), trackingStart: Date) {
        self.schedule = schedule
        self.trackingStart = trackingStart
    }

    // MARK: Status

    public func status(of occurrence: Occurrence, now: Date) -> DoseStatus {
        let grace = TimeInterval(schedule.graceMinutes * 60)
        if let entry = taken.first(where: { $0.dueAt == occurrence.dueAt }) {
            return entry.takenAt > occurrence.dueAt.addingTimeInterval(grace)
                ? .takenLate(at: entry.takenAt) : .taken(at: entry.takenAt)
        }
        if now < occurrence.dueAt { return .upcoming }
        return now <= occurrence.dueAt.addingTimeInterval(grace) ? .due : .missed
    }

    /// The "I took it" button is available from `earlyMinutes` before the dose until it is recorded.
    public func canMarkTaken(_ occurrence: Occurrence, now: Date) -> Bool {
        guard !taken.contains(where: { $0.dueAt == occurrence.dueAt }) else { return false }
        return now >= occurrence.dueAt.addingTimeInterval(-TimeInterval(schedule.earlyMinutes * 60))
    }

    // MARK: Changes

    public mutating func markTaken(_ occurrence: Occurrence, at time: Date) {
        taken.removeAll { $0.dueAt == occurrence.dueAt }
        taken.append(TakenEntry(slot: occurrence.slot, dueAt: occurrence.dueAt, takenAt: time))
    }

    /// For an accidental tap.
    public mutating func undoTaken(_ occurrence: Occurrence) {
        taken.removeAll { $0.dueAt == occurrence.dueAt }
    }

    /// Changing times restarts tracking from `now`; earlier recorded doses stay in the history.
    public mutating func changeSchedule(_ newSchedule: Schedule, now: Date) {
        guard newSchedule != schedule else { return }
        schedule = newSchedule
        trackingStart = now
    }

    public mutating func addSeizure(at time: Date, note: String) {
        seizures.append(SeizureNote(at: time, note: note))
    }

    public mutating func removeSeizure(_ note: SeizureNote) {
        seizures.removeAll { $0.id == note.id }
    }

    // MARK: Reading

    /// Today's scheduled doses (both slots).
    public func today(now: Date, calendar: Calendar) -> [Occurrence] {
        schedule.occurrences(on: now, calendar: calendar)
    }

    /// Past doses newest first: scheduled doses since tracking began, plus anything recorded earlier.
    public func history(now: Date, calendar: Calendar) -> [Occurrence] {
        var all = Set(schedule.occurrences(from: trackingStart, through: now, calendar: calendar))
        for entry in taken where entry.dueAt <= now {
            all.insert(Occurrence(slot: entry.slot, dueAt: entry.dueAt))
        }
        return all.sorted { $0.dueAt > $1.dueAt }
    }

    /// The most recent dose that was missed or taken late.
    public func lastMissedOrLate(now: Date, calendar: Calendar) -> Occurrence? {
        history(now: now, calendar: calendar).first {
            switch status(of: $0, now: now) {
            case .missed, .takenLate: return true
            default: return false
            }
        }
    }
}
