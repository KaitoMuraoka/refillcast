import Foundation
import Testing
@testable import refillcast

struct ReplacementForecastTests {
    private let calendar = TestCalendar.tokyo

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12, _ minute: Int = 0) -> Date {
        TestCalendar.date(year, month, day, hour, minute, calendar: calendar)
    }

    private func forecast(purchases: [Date], cycleDays: Int, today: Date) -> ReplacementForecast {
        ReplacementForecast(purchaseDates: purchases, cycleDays: cycleDays, today: today, calendar: calendar)
    }

    @Test func overdue() {
        // 11/1 + 7日 = 11/8。今日は 11/11 なので 3 日超過。
        let result = forecast(purchases: [date(2026, 11, 1)], cycleDays: 7, today: date(2026, 11, 11))
        #expect(result.dueDay == date(2026, 11, 8, 0))
        #expect(result.remainingDays == -3)
        #expect(result.status == .overdue)
    }

    @Test func overdueByOneDay() {
        let result = forecast(purchases: [date(2026, 11, 1)], cycleDays: 9, today: date(2026, 11, 11))
        #expect(result.remainingDays == -1)
        #expect(result.status == .overdue)
    }

    @Test func dueToday() {
        let result = forecast(purchases: [date(2026, 11, 1)], cycleDays: 10, today: date(2026, 11, 11))
        #expect(result.remainingDays == 0)
        #expect(result.status == .soon)
    }

    @Test func sevenDaysLeftIsSoon() {
        let result = forecast(purchases: [date(2026, 11, 1)], cycleDays: 17, today: date(2026, 11, 11))
        #expect(result.remainingDays == 7)
        #expect(result.status == .soon)
    }

    @Test func eightDaysLeftIsPlenty() {
        let result = forecast(purchases: [date(2026, 11, 1)], cycleDays: 18, today: date(2026, 11, 11))
        #expect(result.remainingDays == 8)
        #expect(result.status == .plenty)
    }

    @Test func notPurchased() {
        let result = forecast(purchases: [], cycleDays: 30, today: date(2026, 11, 11))
        #expect(result.lastPurchaseDay == nil)
        #expect(result.dueDay == nil)
        #expect(result.remainingDays == nil)
        #expect(result.status == .notPurchased)
    }

    @Test func acrossMonths() {
        // 1/25 + 10日 = 2/4
        let result = forecast(purchases: [date(2026, 1, 25)], cycleDays: 10, today: date(2026, 1, 30))
        #expect(result.dueDay == date(2026, 2, 4, 0))
        #expect(result.remainingDays == 5)
    }

    @Test func acrossMonthsWithThirtyDayMonth() {
        // 4/30 + 1日 = 5/1
        let result = forecast(purchases: [date(2026, 4, 30)], cycleDays: 1, today: date(2026, 4, 30))
        #expect(result.dueDay == date(2026, 5, 1, 0))
        #expect(result.remainingDays == 1)
    }

    @Test func acrossYears() {
        // 12/28 + 7日 = 翌年 1/4
        let result = forecast(purchases: [date(2026, 12, 28)], cycleDays: 7, today: date(2026, 12, 30))
        #expect(result.dueDay == date(2027, 1, 4, 0))
        #expect(result.remainingDays == 5)
        #expect(result.status == .soon)
    }

    @Test func overdueAcrossYears() {
        // 12/1 + 30日 = 12/31。今日は翌年 1/2 なので 2 日超過。
        let result = forecast(purchases: [date(2026, 12, 1)], cycleDays: 30, today: date(2027, 1, 2))
        #expect(result.remainingDays == -2)
        #expect(result.status == .overdue)
    }

    @Test func leapYear() {
        // 2028 年はうるう年。2/28 + 1日 = 2/29
        let result = forecast(purchases: [date(2028, 2, 28)], cycleDays: 1, today: date(2028, 2, 28))
        #expect(result.dueDay == date(2028, 2, 29, 0))
        #expect(result.remainingDays == 1)
    }

    @Test func timeOfDayIsIgnored() {
        // 購入は 23:59、今日は 0:01。時刻を無視して日付だけで数える。
        let result = forecast(purchases: [date(2026, 11, 1, 23, 59)], cycleDays: 10, today: date(2026, 11, 11, 0, 1))
        #expect(result.lastPurchaseDay == date(2026, 11, 1, 0))
        #expect(result.remainingDays == 0)
    }

    @Test func usesLatestPurchase() {
        let purchases = [date(2026, 10, 1), date(2026, 11, 5), date(2026, 9, 1)]
        let result = forecast(purchases: purchases, cycleDays: 30, today: date(2026, 11, 11))
        #expect(result.lastPurchaseDay == date(2026, 11, 5, 0))
        #expect(result.dueDay == date(2026, 12, 5, 0))
        #expect(result.remainingDays == 24)
    }

    @Test func purchasedTodayWithOneDayCycle() {
        let result = forecast(purchases: [date(2026, 11, 11)], cycleDays: 1, today: date(2026, 11, 11))
        #expect(result.remainingDays == 1)
        #expect(result.status == .soon)
    }

    @Test func daylightSavingTimeDoesNotShiftDays() {
        // ニューヨークでは 2026/3/8 に夏時間が始まる（1 日が 23 時間）。
        let newYork = TestCalendar.newYork
        let purchase = TestCalendar.date(2026, 3, 1, 12, calendar: newYork)
        let today = TestCalendar.date(2026, 3, 9, 0, 30, calendar: newYork)
        let result = ReplacementForecast(purchaseDates: [purchase], cycleDays: 10, today: today, calendar: newYork)
        #expect(result.dueDay == TestCalendar.date(2026, 3, 11, 0, calendar: newYork))
        #expect(result.remainingDays == 2)
    }

    @Test func cycleBelowOneIsTreatedAsOne() {
        let result = forecast(purchases: [date(2026, 11, 11)], cycleDays: 0, today: date(2026, 11, 11))
        #expect(result.remainingDays == 1)
    }
}

struct ReplacementStatusTests {
    @Test(arguments: [
        (-30, ReplacementStatus.overdue),
        (-1, .overdue),
        (0, .soon),
        (7, .soon),
        (8, .plenty),
        (365, .plenty),
    ])
    func statusFromRemainingDays(remainingDays: Int, expected: ReplacementStatus) {
        #expect(ReplacementStatus(remainingDays: remainingDays) == expected)
    }

    @Test func nilMeansNotPurchased() {
        #expect(ReplacementStatus(remainingDays: nil) == .notPurchased)
    }
}
