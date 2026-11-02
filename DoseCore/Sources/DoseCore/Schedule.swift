import Foundation

/// The two daily dose slots. The app treats all of a person's medication as one dose per slot.
public enum DoseSlot: String, Codable, CaseIterable {
    case morning, evening

    public var title: String {
        switch self {
        case .morning: return "Morning"
        case .evening: return "Evening"
        }
    }
}

public struct DoseTime: Codable, Equatable, Hashable {
    public var hour: Int
    public var minute: Int

    public init(hour: Int, minute: Int) {
        self.hour = hour
        self.minute = minute
    }
}

/// One scheduled dose: a slot on a particular day.
public struct Occurrence: Hashable, Identifiable {
    public let slot: DoseSlot
    public let dueAt: Date
    public var id: Date { dueAt }

    public init(slot: DoseSlot, dueAt: Date) {
        self.slot = slot
        self.dueAt = dueAt
    }
}

public struct Schedule: Codable, Equatable {
    public var morning = DoseTime(hour: 8, minute: 0)
    public var evening = DoseTime(hour: 20, minute: 0)
    /// A dose not recorded within this long after it is due counts as missed.
    public var graceMinutes = 120
    /// "I took it" opens this long before the dose is due.
    public var earlyMinutes = 60
    /// After the first gentle reminder, how often to repeat until she taps "taken".
    public var followUpMinutes = 15
    public var followUpCount = 8

    public init() {}

    public func time(for slot: DoseSlot) -> DoseTime {
        slot == .morning ? morning : evening
    }

    public func occurrences(on day: Date, calendar: Calendar) -> [Occurrence] {
        DoseSlot.allCases.compactMap { slot in
            let t = time(for: slot)
            return calendar.date(bySettingHour: t.hour, minute: t.minute, second: 0, of: day)
                .map { Occurrence(slot: slot, dueAt: $0) }
        }
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
        return result.sorted { $0.dueAt < $1.dueAt }
    }
}
