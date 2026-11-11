import Foundation
import Testing
@testable import refillcast

struct ReminderPlannerTests {
    private let calendar = TestCalendar.tokyo
    private let nine = ReminderTime(hour: 9, minute: 0)

    private func date(_ month: Int, _ day: Int, _ hour: Int = 12, _ minute: Int = 0, year: Int = 2026) -> Date {
        TestCalendar.date(year, month, day, hour, minute, calendar: calendar)
    }

    private func plan(due: Date, lead: ReminderLeadTime, now: Date, time: ReminderTime? = nil) -> ReminderPlan? {
        ReminderPlanner.plan(dueDay: due, leadTime: lead, time: time ?? nine, now: now, calendar: calendar)
    }

    @Test func sameDayAtConfiguredTime() {
        let result = plan(due: date(11, 20, 0), lead: .sameDay, now: date(11, 11))
        #expect(result == ReminderPlan(fireDate: date(11, 20, 9), daysBefore: 0))
    }

    @Test func daysBefore() {
        #expect(plan(due: date(11, 20, 0), lead: .oneDayBefore, now: date(11, 11))?.fireDate == date(11, 19, 9))
        #expect(plan(due: date(11, 20, 0), lead: .threeDaysBefore, now: date(11, 11))?.fireDate == date(11, 17, 9))
    }

    @Test func customTime() {
        let result = plan(due: date(11, 20, 0), lead: .sameDay, now: date(11, 11), time: ReminderTime(hour: 21, minute: 30))
        #expect(result?.fireDate == date(11, 20, 21, 30))
    }

    @Test func fallsBackToDueDayWhenLeadDayHasPassed() {
        // 3日前（11/10）は過ぎているので、当日（11/12）に通知する。
        let result = plan(due: date(11, 12, 0), lead: .threeDaysBefore, now: date(11, 11))
        #expect(result == ReminderPlan(fireDate: date(11, 12, 9), daysBefore: 0))
    }

    @Test func dueTodayBeforeTime() {
        let result = plan(due: date(11, 11, 0), lead: .sameDay, now: date(11, 11, 8, 59))
        #expect(result?.fireDate == date(11, 11, 9))
    }

    @Test func dueTodayAfterTimeIsNotScheduled() {
        #expect(plan(due: date(11, 11, 0), lead: .sameDay, now: date(11, 11, 9, 0)) == nil)
        #expect(plan(due: date(11, 11, 0), lead: .oneDayBefore, now: date(11, 11, 10)) == nil)
    }

    @Test func overdueIsNotScheduled() {
        #expect(plan(due: date(11, 1, 0), lead: .sameDay, now: date(11, 11)) == nil)
    }

    @Test func leadTimeAcrossYear() {
        let result = plan(due: date(1, 2, 0, year: 2027), lead: .threeDaysBefore, now: date(12, 20))
        #expect(result?.fireDate == date(12, 30, 9))
    }
}
