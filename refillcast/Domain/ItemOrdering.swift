import Foundation

/// 一覧の並び順を決めるための値。
nonisolated struct ItemSortKey: Equatable, Sendable {
    /// 買い替え予定日。未購入なら nil。
    let dueDay: Date?
    let name: String
    let createdAt: Date
}

/// 一覧の並び順。
///
/// 1. 買い替え予定日が早い順（期限超過は超過日数が大きいほど上）
/// 2. 予定日が同じなら名前順
/// 3. 未購入は末尾に置き、登録順に並べる
nonisolated enum ItemOrdering {
    static func areInIncreasingOrder(_ lhs: ItemSortKey, _ rhs: ItemSortKey) -> Bool {
        switch (lhs.dueDay, rhs.dueDay) {
        case let (left?, right?):
            if left != right {
                return left < right
            }
            let nameOrder = lhs.name.localizedStandardCompare(rhs.name)
            if nameOrder != .orderedSame {
                return nameOrder == .orderedAscending
            }
            return lhs.createdAt < rhs.createdAt
        case (.some, nil):
            return true
        case (nil, .some):
            return false
        case (nil, nil):
            return lhs.createdAt < rhs.createdAt
        }
    }

    static func sorted<Element>(_ elements: [Element], by key: (Element) -> ItemSortKey) -> [Element] {
        elements.sorted { areInIncreasingOrder(key($0), key($1)) }
    }
}
