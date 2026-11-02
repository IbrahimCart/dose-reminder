import Foundation

public enum Report {
    /// A plain-text summary the person can show or send to their doctor. Contains reminder labels and times.
    public static func text(log: DoseLog, now: Date, calendar: Calendar, days: Int = 30) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE MMM d, h:mm a"

        let cutoff = calendar.date(byAdding: .day, value: -days, to: now) ?? now
        let rows = log.history(now: now, calendar: calendar).filter { $0.dueAt >= cutoff }

        var onTime = 0, late = 0, missed = 0
        var lines: [String] = []
        for occ in rows {
            switch log.status(of: occ, now: now) {
            case .taken(let at):
                onTime += 1
                lines.append("\(formatter.string(from: occ.dueAt)) \(occ.title): taken \(formatter.string(from: at))")
            case .takenLate(let at):
                late += 1
                lines.append("\(formatter.string(from: occ.dueAt)) \(occ.title): LATE, taken \(formatter.string(from: at))")
            case .missed:
                missed += 1
                lines.append("\(formatter.string(from: occ.dueAt)) \(occ.title): MISSED")
            case .upcoming, .due:
                break
            }
        }

        var out = ["Dose record, last \(days) days", ""]
        out.append("On time: \(onTime)   Late: \(late)   Missed: \(missed)")
        out.append("")
        out += lines
        let seizures = log.seizures.filter { $0.at >= cutoff }.sorted { $0.at > $1.at }
        if !seizures.isEmpty {
            out.append("")
            out.append("Notes")
            for s in seizures {
                out.append("\(formatter.string(from: s.at))" + (s.note.isEmpty ? "" : ": \(s.note)"))
            }
        }
        return out.joined(separator: "\n")
    }
}
