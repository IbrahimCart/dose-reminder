import Foundation
import Testing
@testable import DoseCore

struct DoseCoreTests {
    let cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()

    func date(_ d: Int, _ h: Int, _ m: Int = 0) -> Date {
        cal.date(from: DateComponents(year: 2026, month: 11, day: d, hour: h, minute: m))!
    }

    @Test func twoDosesPerDayTwelveHoursApart() {
        let occ = Schedule().occurrences(on: date(2, 12), calendar: cal)
        #expect(occ.map(\.slot) == [.morning, .evening])
        #expect(occ[1].dueAt.timeIntervalSince(occ[0].dueAt) == 12 * 3600)
    }

    @Test func statusProgression() {
        var log = DoseLog(trackingStart: date(2, 0))
        let morning = log.today(now: date(2, 7), calendar: cal)[0]
        #expect(log.status(of: morning, now: date(2, 7)) == .upcoming)
        #expect(log.status(of: morning, now: date(2, 8, 30)) == .due)
        #expect(log.status(of: morning, now: date(2, 10, 1)) == .missed)
        log.markTaken(morning, at: date(2, 8, 4))
        #expect(log.status(of: morning, now: date(2, 12)) == .taken(at: date(2, 8, 4)))
    }

    @Test func doseTakenAfterGraceIsLateNotMissed() {
        var log = DoseLog(trackingStart: date(2, 0))
        let morning = log.today(now: date(2, 7), calendar: cal)[0]
        log.markTaken(morning, at: date(2, 11))
        #expect(log.status(of: morning, now: date(2, 12)) == .takenLate(at: date(2, 11)))
    }

    @Test func takenButtonOpensAnHourEarlyAndClosesOnceRecorded() {
        var log = DoseLog(trackingStart: date(2, 0))
        let morning = log.today(now: date(2, 7), calendar: cal)[0]
        #expect(!(log.canMarkTaken(morning, now: date(2, 6, 59))))
        #expect(log.canMarkTaken(morning, now: date(2, 7)))
        log.markTaken(morning, at: date(2, 7))
        #expect(!(log.canMarkTaken(morning, now: date(2, 7, 5))))
    }

    @Test func undoRestoresPreviousState() {
        var log = DoseLog(trackingStart: date(2, 0))
        let morning = log.today(now: date(2, 9), calendar: cal)[0]
        log.markTaken(morning, at: date(2, 9))
        log.undoTaken(morning)
        #expect(log.status(of: morning, now: date(2, 9)) == .due)
    }

    @Test func installingMidDayDoesNotInventMissedDoses() {
        let log = DoseLog(trackingStart: date(2, 15))
        #expect(log.history(now: date(2, 16), calendar: cal).isEmpty)
        #expect(log.lastMissedOrLate(now: date(2, 16), calendar: cal) == nil)
    }

    @Test func lastMissedFindsMostRecentMissedOrLate() {
        var log = DoseLog(trackingStart: date(1, 0))
        let now = date(3, 12)
        // Day 1 evening: missed. Day 2 morning: late. Everything else on time.
        for occ in log.history(now: now, calendar: cal).reversed() {
            if occ.dueAt == date(1, 20) { continue }
            let at = occ.dueAt == date(2, 8) ? date(2, 11) : occ.dueAt
            log.markTaken(occ, at: at)
        }
        let last = log.lastMissedOrLate(now: now, calendar: cal)
        #expect(last?.dueAt == date(2, 8))
        log.markTaken(Occurrence(slot: .morning, dueAt: date(2, 8)), at: date(2, 8))
        #expect(log.lastMissedOrLate(now: now, calendar: cal)?.dueAt == date(1, 20))
    }

    @Test func changingScheduleKeepsRecordedDoses() {
        var log = DoseLog(trackingStart: date(1, 0))
        let first = log.today(now: date(1, 9), calendar: cal)[0]
        log.markTaken(first, at: date(1, 8))
        var s = Schedule()
        s.morning = DoseTime(hour: 9, minute: 0)
        log.changeSchedule(s, now: date(2, 12))
        let history = log.history(now: date(2, 13), calendar: cal)
        #expect(history.contains { $0.dueAt == date(1, 8) })
        #expect(!(history.contains { $0.dueAt == date(1, 20) }))
    }

    @Test func reminderPlanIsGentleOnceThenFollowUpsUntilTaken() {
        var log = DoseLog(trackingStart: date(2, 0))
        let plan = ReminderPlanner.plan(log: log, now: date(2, 7), calendar: cal, days: 1)
        let morning = plan.filter { $0.occurrence.dueAt == date(2, 8) }
        #expect(morning.first?.kind == .gentle)
        #expect(morning.filter { $0.kind == .followUp }.count == 8)
        #expect(morning[1].fireAt == date(2, 8, 15))

        log.markTaken(log.today(now: date(2, 8), calendar: cal)[0], at: date(2, 8, 2))
        let after = ReminderPlanner.plan(log: log, now: date(2, 8, 3), calendar: cal, days: 1)
        #expect(after.filter { $0.occurrence.dueAt == date(2, 8) }.isEmpty)
        #expect(!(after.isEmpty)) // evening still planned
    }

    @Test func reminderPlanStaysUnderIOSLimit() {
        let log = DoseLog(trackingStart: date(2, 0))
        #expect(ReminderPlanner.plan(log: log, now: date(2, 7), calendar: cal).count < 64)
    }

    @Test func reportIsTimesOnly() {
        var log = DoseLog(trackingStart: date(1, 0))
        let now = date(2, 12)
        let first = log.history(now: now, calendar: cal).last!
        log.markTaken(first, at: first.dueAt)
        log.addSeizure(at: date(1, 15), note: "short, felt tired after")
        let text = Report.text(log: log, now: now, calendar: cal)
        #expect(text.contains("On time: 1"))
        #expect(text.contains("MISSED"))
        #expect(text.contains("short, felt tired after"))
    }

    @Test func storeRoundTrip() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("doses-\(UUID()).json")
        defer { try? FileManager.default.removeItem(at: url) }
        var log = DoseLog(trackingStart: date(1, 0))
        log.markTaken(Occurrence(slot: .morning, dueAt: date(1, 8)), at: date(1, 8, 2))
        let store = JSONFileStore(url: url)
        try store.save(log)
        #expect(store.load() == log)
    }
}
