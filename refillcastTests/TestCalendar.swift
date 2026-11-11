import Foundation

/// テストで使う、タイムゾーンを固定したカレンダーと日付の作成。
enum TestCalendar {
    static let tokyo: Calendar = calendar(timeZone: "Asia/Tokyo")
    static let newYork: Calendar = calendar(timeZone: "America/New_York")

    static func calendar(timeZone identifier: String) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: identifier)!
        return calendar
    }

    static func date(
        _ year: Int, _ month: Int, _ day: Int,
        _ hour: Int = 12, _ minute: Int = 0,
        calendar: Calendar = TestCalendar.tokyo
    ) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }
}
