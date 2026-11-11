import Foundation
import Observation

/// 一覧画面から開くシート。
enum ItemListSheet: Identifiable {
    case itemForm(ItemFormViewModel)
    case settings(SettingsViewModel)

    var id: ObjectIdentifier {
        switch self {
        case .itemForm(let viewModel): ObjectIdentifier(viewModel)
        case .settings(let viewModel): ObjectIdentifier(viewModel)
        }
    }
}

/// 「買った」の取り消しに必要な情報。
struct PurchaseUndo: Identifiable {
    let id = UUID()
    let itemID: UUID
    let purchase: Purchase
    let message: String
}

@MainActor
@Observable
final class ItemListViewModel {
    /// 「買った」の取り消しを受け付ける時間。
    static let undoDuration: Duration = .seconds(5)

    var activeSheet: ItemListSheet?
    private(set) var undo: PurchaseUndo?
    private(set) var pendingDeletion: ItemRowModel?

    @ObservationIgnored let store: ItemStore
    @ObservationIgnored private let settingsViewModel: SettingsViewModel?
    @ObservationIgnored private var undoDismissTask: Task<Void, Never>?

    init(store: ItemStore, settingsViewModel: SettingsViewModel? = nil) {
        self.store = store
        self.settingsViewModel = settingsViewModel
    }

    // MARK: - 表示

    /// 買い替え予定日が近い順の行。
    var rows: [ItemRowModel] {
        let entries = store.items.map { (item: $0, forecast: store.forecast(for: $0)) }
        let sorted = ItemOrdering.sorted(entries) {
            ItemSortKey(dueDay: $0.forecast.dueDay, name: $0.item.name, createdAt: $0.item.createdAt)
        }
        return sorted.map { entry in
            ItemRowModel(
                id: entry.item.uuid,
                name: entry.item.name,
                status: entry.forecast.status,
                remainingText: ForecastText.remaining(entry.forecast.remainingDays),
                dueDateText: entry.forecast.dueDay.map {
                    ForecastText.shortDate($0, today: store.today, calendar: store.calendar)
                }
            )
        }
    }

    /// 品目が 1 件もない。
    var isEmpty: Bool {
        store.items.isEmpty
    }

    // MARK: - エラー

    var errorMessage: String {
        store.errorMessage ?? ""
    }

    var isErrorPresented: Bool {
        get { store.errorMessage != nil }
        set { if !newValue { store.clearError() } }
    }

    // MARK: - 画面の出来事

    /// アプリが前面に来たとき。「今日」を更新し、通知を予約し直す
    /// （設定アプリで通知を許可して戻ってきた場合にも予約されるようにする）。
    func sceneDidBecomeActive() {
        store.refreshToday()
        store.rescheduleAllReminders()
    }

    // MARK: - 設定

    var canShowSettings: Bool {
        settingsViewModel != nil
    }

    func presentSettings() {
        guard let settingsViewModel else { return }
        activeSheet = .settings(settingsViewModel)
    }

    // MARK: - 登録

    func presentNewItemForm() {
        activeSheet = .itemForm(ItemFormViewModel(store: store, mode: .create))
    }

    // MARK: - 詳細

    func makeDetailViewModel(for itemID: UUID) -> ItemDetailViewModel {
        ItemDetailViewModel(itemID: itemID, store: store)
    }

    // MARK: - 買った

    func markPurchased(_ itemID: UUID) {
        guard let item = store.item(withID: itemID),
              let purchase = store.recordPurchase(for: item)
        else { return }
        showUndo(PurchaseUndo(
            itemID: itemID,
            purchase: purchase,
            message: String(localized: "「\(item.name)」を購入済みにしました")
        ))
    }

    func undoLastPurchase() {
        guard let undo else { return }
        store.deletePurchase(undo.purchase)
        dismissUndo()
    }

    func dismissUndo() {
        undoDismissTask?.cancel()
        undoDismissTask = nil
        undo = nil
    }

    private func showUndo(_ newUndo: PurchaseUndo) {
        undoDismissTask?.cancel()
        undo = newUndo
        let undoID = newUndo.id
        let duration = Self.undoDuration
        undoDismissTask = Task { [weak self] in
            try? await Task.sleep(for: duration)
            guard !Task.isCancelled, let self, self.undo?.id == undoID else { return }
            self.undo = nil
        }
    }

    // MARK: - 削除

    var isDeleteConfirmationPresented: Bool {
        get { pendingDeletion != nil }
        set { if !newValue { pendingDeletion = nil } }
    }

    var deleteConfirmationTitle: String {
        guard let pendingDeletion else { return "" }
        return String(localized: "「\(pendingDeletion.name)」を削除しますか？")
    }

    func requestDeletion(_ itemID: UUID) {
        pendingDeletion = rows.first { $0.id == itemID }
    }

    func confirmDeletion(of itemID: UUID) {
        pendingDeletion = nil
        guard let item = store.item(withID: itemID) else { return }
        if undo?.itemID == itemID {
            dismissUndo()
        }
        store.deleteItem(item)
    }
}
