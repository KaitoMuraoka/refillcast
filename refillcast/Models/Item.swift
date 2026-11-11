import Foundation
import SwiftData

extension RefillcastSchemaV1 {
    /// 品目。購入日は持たず、購入のたびに `Purchase` を追加する。
    @Model
    final class Item {
        /// 通知の識別子など、端末の外でも安定して使える ID。
        var uuid: UUID = UUID()
        var name: String = ""
        var cycleDays: Int = 30
        var memo: String = ""
        var createdAt: Date = Date.now

        /// 購入履歴。Item を削除すると、紐づく Purchase も削除される。
        @Relationship(deleteRule: .cascade, inverse: \Purchase.item)
        var purchases: [Purchase] = []

        init(
            uuid: UUID = UUID(),
            name: String,
            cycleDays: Int,
            memo: String = "",
            createdAt: Date = .now
        ) {
            self.uuid = uuid
            self.name = name
            self.cycleDays = cycleDays
            self.memo = memo
            self.createdAt = createdAt
        }
    }
}
