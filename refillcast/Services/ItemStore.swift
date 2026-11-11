import Foundation
import Observation
import SwiftData

/// 品目と購入履歴の読み書きをまとめる。
///
/// 変更のたびに保存し、通知を予約し直す。ViewModel はこのクラスを通してデータを扱う。
@MainActor
@Observable
final class ItemStore {
    /// 登録順の品目一覧。
    private(set) var items: [Item] = []
    /// 予報に使う「今日」。アプリが前面に戻ったときなどに `refreshToday()` で更新する。
    private(set) var today: Date
    /// 直近の保存に失敗したときのメッセージ。
    private(set) var errorMessage: String?

    @ObservationIgnored let calendar: Calendar
    @ObservationIgnored private let context: ModelContext
    @ObservationIgnored private let reminders: any ReminderScheduling
    @ObservationIgnored private let cycleEstimator: any CycleEstimating
    @ObservationIgnored private let now: () -> Date

    init(
        context: ModelContext,
        reminders: any ReminderScheduling,
        cycleEstimator: any CycleEstimating = FixedCycleEstimator(),
        calendar: Calendar = .current,
        now: @escaping () -> Date = { Date.now }
    ) {
        self.context = context
        self.reminders = reminders
        self.cycleEstimator = cycleEstimator
        self.calendar = calendar
        self.now = now
        self.today = now()
        reload()
    }

    // MARK: - 読み込み

    func reload() {
        do {
            let descriptor = FetchDescriptor<Item>(sortBy: [SortDescriptor(\.createdAt)])
            items = try context.fetch(descriptor)
        } catch {
            items = []
            errorMessage = String(localized: "データを読み込めませんでした。")
        }
    }

    func refreshToday() {
        today = now()
    }

    func item(withID id: UUID) -> Item? {
        items.first { $0.uuid == id }
    }

    func forecast(for item: Item) -> ReplacementForecast {
        let purchaseDates = item.purchases.map(\.purchasedAt)
        let cycleDays = cycleEstimator.cycleDays(
            configuredCycleDays: item.cycleDays,
            purchaseDates: purchaseDates
        )
        return ReplacementForecast(
            purchaseDates: purchaseDates,
            cycleDays: cycleDays,
            today: today,
            calendar: calendar
        )
    }

    func reminderSources() -> [ReminderSource] {
        items.map(reminderSource(for:))
    }

    func clearError() {
        errorMessage = nil
    }

    // MARK: - 品目

    @discardableResult
    func addItem(_ draft: ItemDraft) -> Item? {
        guard draft.isValid, let cycleDays = draft.cycleDays else { return nil }
        let item = Item(
            name: draft.trimmedName,
            cycleDays: cycleDays,
            memo: draft.trimmedMemo,
            createdAt: now()
        )
        context.insert(item)
        if let date = draft.initialPurchaseDate {
            item.purchases.append(Purchase(purchasedAt: date))
        }
        guard save() else { return nil }
        reload()
        reminders.requestAuthorizationIfNeeded()
        reminders.reschedule(reminderSource(for: item))
        return item
    }

    @discardableResult
    func updateItem(_ item: Item, with draft: ItemDraft) -> Bool {
        guard draft.isValid, let cycleDays = draft.cycleDays else { return false }
        item.name = draft.trimmedName
        item.cycleDays = cycleDays
        item.memo = draft.trimmedMemo
        guard save() else { return false }
        reminders.reschedule(reminderSource(for: item))
        return true
    }

    func deleteItem(_ item: Item) {
        let itemID = item.uuid
        context.delete(item)
        guard save() else { return }
        reload()
        reminders.cancel(itemID: itemID)
    }

    // MARK: - 購入履歴

    /// 購入を記録する。`date` を省略すると現在日時で記録する。
    @discardableResult
    func recordPurchase(for item: Item, on date: Date? = nil) -> Purchase? {
        refreshToday()
        let purchase = Purchase(purchasedAt: date ?? now())
        item.purchases.append(purchase)
        guard save() else { return nil }
        reminders.reschedule(reminderSource(for: item))
        return purchase
    }

    func deletePurchase(_ purchase: Purchase) {
        let item = purchase.item
        item?.purchases.removeAll { $0.persistentModelID == purchase.persistentModelID }
        context.delete(purchase)
        guard save() else { return }
        if let item {
            reminders.reschedule(reminderSource(for: item))
        }
    }

    // MARK: - 内部

    private func reminderSource(for item: Item) -> ReminderSource {
        ReminderSource(itemID: item.uuid, name: item.name, dueDay: forecast(for: item).dueDay)
    }

    /// 保存する。失敗したら変更を取り消し、エラーメッセージを設定する。
    private func save() -> Bool {
        do {
            try context.save()
            return true
        } catch {
            context.rollback()
            reload()
            errorMessage = String(localized: "保存できませんでした。もう一度お試しください。")
            return false
        }
    }
}
