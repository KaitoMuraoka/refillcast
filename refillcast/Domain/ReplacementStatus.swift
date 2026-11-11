import Foundation

/// 買い替えの状態。
nonisolated enum ReplacementStatus: Equatable, Hashable, Sendable {
    /// 残り日数が 0 未満。
    case overdue
    /// 残り日数が 0〜7。
    case soon
    /// 残り日数が 8 以上。
    case plenty
    /// 購入履歴が 1 件もない。
    case notPurchased

    /// 「そろそろ」とみなす残り日数の上限。
    static let soonThresholdDays = 7

    init(remainingDays: Int?) {
        guard let remainingDays else {
            self = .notPurchased
            return
        }
        if remainingDays < 0 {
            self = .overdue
        } else if remainingDays <= Self.soonThresholdDays {
            self = .soon
        } else {
            self = .plenty
        }
    }
}
