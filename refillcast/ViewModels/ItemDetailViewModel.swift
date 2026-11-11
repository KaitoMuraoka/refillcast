import Foundation
import Observation
import SwiftData

/// 購入履歴の 1 行に表示する内容。
nonisolated struct PurchaseRowModel: Identifiable, Equatable, Sendable {
    let id: PersistentIdentifier
    let dateText: String
}

/// 詳細画面の ViewModel。
@MainActor
@Observable
final class ItemDetailViewModel {
    let itemID: UUID
    var editForm: ItemFormViewModel?
    var isAddingPurchase = false
    var newPurchaseDate: Date

    @ObservationIgnored private let store: ItemStore

    init(itemID: UUID, store: ItemStore) {
        self.itemID = itemID
        self.store = store
        self.newPurchaseDate = store.today
    }

    // MARK: - 表示

    /// 品目が削除されていれば false。
    var isAvailable: Bool {
        item != nil
    }

    var name: String {
        item?.name ?? ""
    }

    var cycleText: String {
        guard let item else { return "" }
        return ForecastText.cycle(item.cycleDays)
    }

    var status: ReplacementStatus {
        forecast?.status ?? .notPurchased
    }

    var remainingText: String {
        ForecastText.remaining(forecast?.remainingDays)
    }

    var dueDateText: String {
        guard let dueDay = forecast?.dueDay else { return String(localized: "未購入") }
        return ForecastText.longDate(dueDay)
    }

    var lastPurchaseText: String {
        guard let lastPurchaseDay = forecast?.lastPurchaseDay else { return String(localized: "未購入") }
        return ForecastText.longDate(lastPurchaseDay)
    }

    var memo: String {
        item?.memo ?? ""
    }

    var hasMemo: Bool {
        !memo.isEmpty
    }

    /// 新しい順の購入履歴。
    var purchaseRows: [PurchaseRowModel] {
        sortedPurchases.map {
            PurchaseRowModel(id: $0.persistentModelID, dateText: ForecastText.longDate($0.purchasedAt))
        }
    }

    var hasPurchases: Bool {
        !(item?.purchases.isEmpty ?? true)
    }

    var latestSelectablePurchaseDate: Date {
        store.endOfToday
    }

    // MARK: - 操作

    func startEditing() {
        guard let item else { return }
        editForm = ItemFormViewModel(store: store, mode: .edit(item))
    }

    func startAddingPurchase() {
        newPurchaseDate = store.today
        isAddingPurchase = true
    }

    func cancelAddingPurchase() {
        isAddingPurchase = false
    }

    func addPurchase() {
        guard let item else { return }
        store.recordPurchase(for: item, on: min(newPurchaseDate, store.endOfToday))
        isAddingPurchase = false
    }

    func deletePurchases(at offsets: IndexSet) {
        let purchases = sortedPurchases
        for index in offsets where purchases.indices.contains(index) {
            store.deletePurchase(purchases[index])
        }
    }

    // MARK: - 内部

    private var item: Item? {
        store.item(withID: itemID)
    }

    private var forecast: ReplacementForecast? {
        item.map { store.forecast(for: $0) }
    }

    private var sortedPurchases: [Purchase] {
        (item?.purchases ?? []).sorted { $0.purchasedAt > $1.purchasedAt }
    }
}
