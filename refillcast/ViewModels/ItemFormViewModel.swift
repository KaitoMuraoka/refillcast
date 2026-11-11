import Foundation
import Observation

/// 周期の候補。
nonisolated struct CyclePresetOption: Identifiable, Equatable, Sendable {
    let days: Int
    var id: Int { days }
}

/// 登録・編集画面の ViewModel。
@MainActor
@Observable
final class ItemFormViewModel: Identifiable {
    enum Mode {
        case create
        case edit(Item)
    }

    var name: String
    var cycleDaysText: String
    var memo: String
    /// 新規登録時に、最後に買った日を記録するかどうか。
    var recordsInitialPurchase = true
    var initialPurchaseDate: Date

    @ObservationIgnored private let store: ItemStore
    @ObservationIgnored private let mode: Mode

    init(store: ItemStore, mode: Mode) {
        self.store = store
        self.mode = mode
        self.initialPurchaseDate = store.today
        switch mode {
        case .create:
            name = ""
            cycleDaysText = String(ItemRules.defaultCycleDays)
            memo = ""
        case .edit(let item):
            name = item.name
            cycleDaysText = String(item.cycleDays)
            memo = item.memo
        }
    }

    // MARK: - 表示

    var title: String {
        switch mode {
        case .create: String(localized: "品目を登録")
        case .edit: String(localized: "品目を編集")
        }
    }

    /// 「最後に買った日」は新規登録のときだけ入力する。登録後は購入履歴で管理する。
    var showsInitialPurchase: Bool {
        if case .create = mode { return true }
        return false
    }

    var nameCountText: String {
        String(localized: "\(draft.trimmedName.count)/\(ItemRules.nameMaxLength)")
    }

    var isNameTooLong: Bool {
        draft.nameIssue == .tooLong
    }

    var nameErrorMessage: String? {
        guard isNameTooLong else { return nil }
        return String(localized: "名前は\(ItemRules.nameMaxLength)文字以内で入力してください")
    }

    var cycleErrorMessage: String? {
        guard !cycleDaysText.isEmpty, let issue = draft.cycleIssue else { return nil }
        switch issue {
        case .missing:
            return String(localized: "数字で入力してください")
        case .outOfRange:
            let range = ItemRules.cycleDaysRange
            return String(localized: "\(range.lowerBound)〜\(range.upperBound)日の範囲で入力してください")
        }
    }

    var cyclePresets: [CyclePresetOption] {
        ItemRules.cycleDayPresets.map(CyclePresetOption.init(days:))
    }

    func presetLabel(_ preset: CyclePresetOption) -> String {
        String(localized: "\(preset.days)日")
    }

    /// 購入日に選べる最後の日時（今日の終わり）。未来の日付は選べない。
    var latestSelectablePurchaseDate: Date {
        store.endOfToday
    }

    var canSave: Bool {
        draft.isValid
    }

    // MARK: - 操作

    func selectPreset(_ preset: CyclePresetOption) {
        cycleDaysText = String(preset.days)
    }

    /// 保存する。成功したら true を返す。
    func save() -> Bool {
        let draft = draft
        guard draft.isValid else { return false }
        switch mode {
        case .create:
            return store.addItem(draft) != nil
        case .edit(let item):
            return store.updateItem(item, with: draft)
        }
    }

    // MARK: - 内部

    private var draft: ItemDraft {
        ItemDraft(
            name: name,
            cycleDays: ItemDraft.parseCycleDays(cycleDaysText),
            memo: memo,
            initialPurchaseDate: showsInitialPurchase && recordsInitialPurchase ? initialPurchaseDate : nil
        )
    }
}
