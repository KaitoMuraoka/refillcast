import Foundation

/// 予報に使う周期（日数）を決める。
///
/// 将来、購入間隔の平均から周期を自動計算する機能を足すときは、
/// このプロトコルに準拠した型を追加して `ItemStore` に渡す。
nonisolated protocol CycleEstimating: Sendable {
    func cycleDays(configuredCycleDays: Int, purchaseDates: [Date]) -> Int
}

/// 登録された周期をそのまま使う。
nonisolated struct FixedCycleEstimator: CycleEstimating {
    func cycleDays(configuredCycleDays: Int, purchaseDates: [Date]) -> Int {
        configuredCycleDays
    }
}
