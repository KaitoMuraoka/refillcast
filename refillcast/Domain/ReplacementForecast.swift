import Foundation

/// 1 つの品目について、次の買い替え時期を予報した結果。
///
/// ビューや SwiftData に依存しない純粋な値型。「今日」とカレンダーを引数で受け取るのでテストできる。
/// 日付はすべてカレンダー上の「日」の単位で扱い、時刻は無視する。
nonisolated struct ReplacementForecast: Equatable, Sendable {
    /// 最終購入日（その日の 0 時）。未購入なら nil。
    let lastPurchaseDay: Date?
    /// 次回の買い替え予定日（その日の 0 時）。未購入なら nil。
    let dueDay: Date?
    /// 買い替え予定日 − 今日（日数）。未購入なら nil。
    let remainingDays: Int?
    let status: ReplacementStatus

    /// - Parameters:
    ///   - purchaseDates: 購入日の一覧（順不同）。
    ///   - cycleDays: 買い替えの周期（日数）。1 未満は 1 として扱う。
    ///   - today: 今日の日付（時刻は無視する）。
    ///   - calendar: 日付の計算に使うカレンダー。
    init(purchaseDates: [Date], cycleDays: Int, today: Date, calendar: Calendar) {
        guard let lastPurchase = purchaseDates.max() else {
            self.lastPurchaseDay = nil
            self.dueDay = nil
            self.remainingDays = nil
            self.status = .notPurchased
            return
        }

        let lastPurchaseDay = calendar.startOfDay(for: lastPurchase)
        let dueDay = calendar.date(byAdding: .day, value: max(cycleDays, 1), to: lastPurchaseDay)
            .map { calendar.startOfDay(for: $0) }
        let remainingDays = dueDay.flatMap {
            calendar.dateComponents([.day], from: calendar.startOfDay(for: today), to: $0).day
        }

        self.lastPurchaseDay = lastPurchaseDay
        self.dueDay = dueDay
        self.remainingDays = remainingDays
        self.status = ReplacementStatus(remainingDays: remainingDays)
    }
}
