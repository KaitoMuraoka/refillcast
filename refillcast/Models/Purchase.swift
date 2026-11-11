import Foundation
import SwiftData

extension RefillcastSchemaV1 {
    /// 購入履歴の 1 件。
    @Model
    final class Purchase {
        var purchasedAt: Date = Date.now
        var item: Item?

        init(purchasedAt: Date, item: Item? = nil) {
            self.purchasedAt = purchasedAt
            self.item = item
        }
    }
}
