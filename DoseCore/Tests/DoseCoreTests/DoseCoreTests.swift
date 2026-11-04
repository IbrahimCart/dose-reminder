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

    /// The morning reminder of a default schedule.
    var morningReminder: Reminder { Schedule().reminders[0] }

    func occurrence(_ r: Reminder, _ dueAt: Date) -> Occurrence {
        Occurrence(reminderID: r.id, title: r.title, dueAt: dueAt)
    }

    @Test func defaultsAreTwoDosesPerDayTwelveHoursApart() {
        let occ = Schedule().occurrences(on: date(2, 12), calendar: cal)
        #expect(occ.map(\.title) == ["Morning", "Evening"])
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
        log.markTaken(occurrence(morningReminder, date(2, 8)), at: date(2, 8))
        #expect(log.lastMissedOrLate(now: now, calendar: cal)?.dueAt == date(1, 20))
    }

    @Test func changingScheduleKeepsRecordedDoses() {
        var log = DoseLog(trackingStart: date(1, 0))
        let first = log.today(now: date(1, 9), calendar: cal)[0]
        log.markTaken(first, at: date(1, 8))
        var s = Schedule()
        s.reminders[0].time = DoseTime(hour: 9, minute: 0)
        log.changeSchedule(s, now: date(2, 12))
        let history = log.history(now: date(2, 13), calendar: cal)
        #expect(history.contains { $0.dueAt == date(1, 8) })
        #expect(!(history.contains { $0.dueAt == date(1, 20) }))
    }

    // MARK: Custom reminders

    @Test func personCanAddRenameAndRemoveReminders() {
        var s = Schedule()
        s.reminders.append(Reminder(title: "Lunch", time: DoseTime(hour: 12, minute: 30)))
        #expect(s.occurrences(on: date(2, 6), calendar: cal).map(\.title) == ["Morning", "Lunch", "Evening"])
        s.reminders[2].title = "Midday"
        s.reminders.removeAll { $0.title == "Evening" }
        #expect(s.occurrences(on: date(2, 6), calendar: cal).map(\.title) == ["Morning", "Midday"])
    }

    @Test func disabledReminderHasNoDosesOrNotifications() {
        var s = Schedule()
        s.reminders[1].isEnabled = false
        var log = DoseLog(trackingStart: date(2, 0))
        log.changeSchedule(s, now: date(2, 0))
        #expect(log.today(now: date(2, 7), calendar: cal).map(\.title) == ["Morning"])
        let plan = ReminderPlanner.plan(log: log, now: date(2, 7), calendar: cal, days: 1)
        #expect(plan.allSatisfy { $0.occurrence.title == "Morning" })
    }

    @Test func twoRemindersAtTheSameTimeAreTrackedSeparately() {
        var s = Schedule()
        s.reminders.append(Reminder(title: "Extra", time: s.reminders[0].time))
        var log = DoseLog(trackingStart: date(2, 0))
        log.changeSchedule(s, now: date(2, 0))
        let both = log.today(now: date(2, 8), calendar: cal).filter { $0.dueAt == date(2, 8) }
        #expect(both.count == 2)
        log.markTaken(both[0], at: date(2, 8, 1))
        #expect(log.status(of: both[0], now: date(2, 8, 5)) == .taken(at: date(2, 8, 1)))
        #expect(log.status(of: both[1], now: date(2, 8, 5)) == .due)
    }

    @Test func renamingKeepsTrackingAndHistory() {
        var log = DoseLog(trackingStart: date(1, 0))
        let first = log.today(now: date(1, 9), calendar: cal)[0]
        log.markTaken(first, at: date(1, 8))
        var s = log.schedule
        s.reminders[0].title = "Breakfast"
        log.changeSchedule(s, now: date(2, 12))
        let history = log.history(now: date(2, 13), calendar: cal)
        #expect(history.contains { $0.dueAt == date(1, 20) }) // tracking was not restarted
        #expect(history.filter { $0.dueAt == date(1, 8) }.count == 1) // not split into two rows
    }

    @Test func deletedReminderKeepsItsRecordedHistoryUnderTheOldLabel() {
        var log = DoseLog(trackingStart: date(1, 0))
        let first = log.today(now: date(1, 9), calendar: cal)[0]
        log.markTaken(first, at: date(1, 8))
        var s = log.schedule
        s.reminders.removeAll { $0.id == first.reminderID }
        log.changeSchedule(s, now: date(2, 12))
        let row = log.history(now: date(2, 13), calendar: cal).first { $0.dueAt == date(1, 8) }
        #expect(row?.title == "Morning")
    }

    // MARK: Missed-after time

    @Test func typedHoursAndMinutesBecomeOneLengthOfTime() {
        #expect(Schedule.clampedGraceMinutes(hours: 1, minutes: 30) == 90)
        #expect(Schedule.clampedGraceMinutes(hours: 0, minutes: 90) == 90) // 90 minutes is 1 hour 30
        #expect(Schedule.clampedGraceMinutes(hours: 2, minutes: 0) == 120)
        #expect(Schedule.clampedGraceMinutes(hours: 0, minutes: 5) == 5)
    }

    @Test func missedAfterTimeStaysBetweenOneMinuteAndTwentyFourHours() {
        #expect(Schedule.clampedGraceMinutes(hours: 0, minutes: 0) == Schedule.minGraceMinutes)
        #expect(Schedule.clampedGraceMinutes(hours: 99, minutes: 99) == Schedule.maxGraceMinutes)
        #expect(Schedule.clampedGraceMinutes(-30) == Schedule.minGraceMinutes)
        #expect(Schedule.clampedGraceMinutes(Schedule.maxGraceMinutes + Schedule.graceStepMinutes) == Schedule.maxGraceMinutes)
    }

    @Test func aShorterMissedAfterTimeMakesALaterDoseMissedSooner() {
        var log = DoseLog(trackingStart: date(2, 0))
        var s = log.schedule
        s.graceMinutes = Schedule.clampedGraceMinutes(hours: 0, minutes: 30)
        log.changeSchedule(s, now: date(2, 0))
        let morning = log.today(now: date(2, 8, 45), calendar: cal)[0]
        #expect(log.status(of: morning, now: date(2, 8, 45)) == .missed) // 30 minutes after 8:00 has passed
        #expect(log.status(of: morning, now: date(2, 8, 20)) == .due)
    }

    // MARK: Reminders and storage

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

    @Test func reminderPlanStaysUnderIOSLimitEvenWithTheMaximumReminders() {
        var s = Schedule()
        for i in 2..<Schedule.maxReminders {
            s.reminders.append(Reminder(title: "Reminder \(i + 1)", time: DoseTime(hour: 6 + i, minute: 10)))
        }
        #expect(s.reminders.count == Schedule.maxReminders)
        var log = DoseLog(trackingStart: date(2, 0))
        log.changeSchedule(s, now: date(2, 0))
        let plan = ReminderPlanner.plan(log: log, now: date(2, 5), calendar: cal)
        #expect(plan.count == ReminderPlanner.maxPending)
        #expect(Set(plan.map(\.id)).count == plan.count) // every notification id is unique
        #expect(plan == plan.sorted { $0.fireAt < $1.fireAt }) // soonest are the ones kept
    }

    @Test func reportListsLabelsAndTimes() {
        var log = DoseLog(trackingStart: date(1, 0))
        let now = date(2, 12)
        let first = log.history(now: now, calendar: cal).last!
        log.markTaken(first, at: first.dueAt)
        log.addSeizure(at: date(1, 15), note: "felt dizzy after")
        let text = Report.text(log: log, now: now, calendar: cal)
        #expect(text.contains("On time: 1"))
        #expect(text.contains("Morning: taken"))
        #expect(text.contains("MISSED"))
        #expect(text.contains("felt dizzy after"))
    }

    @Test func storeRoundTripKeepsCustomReminders() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("doses-\(UUID()).json")
        defer { try? FileManager.default.removeItem(at: url) }
        var s = Schedule()
        s.reminders.append(Reminder(title: "Lunch", time: DoseTime(hour: 12, minute: 30)))
        var log = DoseLog(schedule: s, trackingStart: date(1, 0))
        log.markTaken(occurrence(morningReminder, date(1, 8)), at: date(1, 8, 2))
        let store = JSONFileStore(url: url)
        try store.save(log)
        #expect(store.load() == log)
    }
}
