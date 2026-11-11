import Foundation

/// 買い替え予定日の何日前に通知するか。
nonisolated enum ReminderLeadTime: Int, CaseIterable, Hashable, Sendable {
    case sameDay = 0
    case oneDayBefore = 1
    case threeDaysBefore = 3

    var daysBefore: Int { rawValue }
}

/// 通知する時刻。
nonisolated struct ReminderTime: Equatable, Hashable, Sendable {
    var hour: Int
    var minute: Int

    static let defaultTime = ReminderTime(hour: 9, minute: 0)
}

/// 通知を出す日時と、それが予定日の何日前か。
nonisolated struct ReminderPlan: Equatable, Sendable {
    let fireDate: Date
    let daysBefore: Int
}

/// 通知の日時を決める純粋な関数。
nonisolated enum ReminderPlanner {
    /// - Returns: 通知する日時。次の順に、`now` より後になる最初のものを選ぶ。
    ///   1. 予定日の `leadTime` 日前の `time`
    ///   2. 予定日当日の `time`
    ///   どちらも過ぎていれば nil（通知しない）。
    static func plan(
        dueDay: Date,
        leadTime: ReminderLeadTime,
        time: ReminderTime,
        now: Date,
        calendar: Calendar
    ) -> ReminderPlan? {
        let due = calendar.startOfDay(for: dueDay)
        var candidates = [leadTime.daysBefore]
        if leadTime.daysBefore != 0 {
            candidates.append(0)
        }
        for daysBefore in candidates {
            guard let day = calendar.date(byAdding: .day, value: -daysBefore, to: due),
                  let fireDate = calendar.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: day)
            else { continue }
            if fireDate > now {
                return ReminderPlan(fireDate: fireDate, daysBefore: daysBefore)
            }
        }
        return nil
    }
}
