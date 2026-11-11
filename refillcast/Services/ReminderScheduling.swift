import Foundation

/// 通知の予約に必要な、品目ごとの情報。
nonisolated struct ReminderSource: Equatable, Sendable {
    let itemID: UUID
    let name: String
    /// 買い替え予定日。未購入なら nil（通知しない）。
    let dueDay: Date?
}

/// 品目の変更に合わせて通知を予約し直す。
@MainActor
protocol ReminderScheduling: AnyObject {
    /// 通知の許可がまだ決まっていなければ、許可を求める。
    func requestAuthorizationIfNeeded()
    /// 1 件の品目の通知を予約し直す。
    func reschedule(_ source: ReminderSource)
    /// すべての品目の通知を予約し直す。
    func rescheduleAll(_ sources: [ReminderSource])
    /// 品目の通知を取り消す。
    func cancel(itemID: UUID)
}
