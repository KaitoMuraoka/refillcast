import Foundation
import SwiftUI

/// 予報を画面に出すときの文言。
enum ForecastText {
    /// 「あと5日」「今日」「3日超過」「未購入」
    static func remaining(_ remainingDays: Int?) -> String {
        guard let remainingDays else {
            return String(localized: "未購入")
        }
        if remainingDays < 0 {
            return String(localized: "\(-remainingDays)日超過")
        }
        if remainingDays == 0 {
            return String(localized: "今日")
        }
        return String(localized: "あと\(remainingDays)日")
    }

    /// 一覧用の短い日付。今日と年が違うときだけ年を付ける。
    static func shortDate(_ date: Date, today: Date, calendar: Calendar) -> String {
        let isSameYear = calendar.component(.year, from: date) == calendar.component(.year, from: today)
        let style: Date.FormatStyle = isSameYear
            ? .dateTime.month().day()
            : .dateTime.year().month().day()
        return date.formatted(style)
    }

    /// 詳細用の日付（年月日と曜日）。
    static func longDate(_ date: Date) -> String {
        date.formatted(.dateTime.year().month().day().weekday(.abbreviated))
    }

    /// 「30日ごと」
    static func cycle(_ cycleDays: Int) -> String {
        String(localized: "\(cycleDays)日ごと")
    }
}

/// 状態ごとの表示（ラベル、アイコン、色）。
extension ReplacementStatus {
    var label: String {
        switch self {
        case .overdue: String(localized: "期限超過")
        case .soon: String(localized: "そろそろ")
        case .plenty: String(localized: "余裕あり")
        case .notPurchased: String(localized: "未購入")
        }
    }

    var symbolName: String {
        switch self {
        case .overdue: "exclamationmark.circle.fill"
        case .soon: "clock.fill"
        case .plenty: "checkmark.circle.fill"
        case .notPurchased: "circle.dashed"
        }
    }

    var tint: Color {
        switch self {
        case .overdue: .red
        case .soon: .orange
        case .plenty: .green
        case .notPurchased: .secondary
        }
    }
}
