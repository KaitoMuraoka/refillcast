import Foundation

/// 品目の入力に関する決まりごと。
nonisolated enum ItemRules {
    static let nameMaxLength = 30
    static let cycleDaysRange = 1...3650
    /// 周期の候補（日数）。
    static let cycleDayPresets = [7, 14, 30, 60, 90, 180, 365]
    static let defaultCycleDays = 30
}

/// 登録・編集画面で入力中の品目。保存できるかどうかの判定を持つ。
nonisolated struct ItemDraft: Equatable, Sendable {
    nonisolated enum NameIssue: Equatable, Sendable {
        case empty
        case tooLong
    }

    nonisolated enum CycleIssue: Equatable, Sendable {
        case missing
        case outOfRange
    }

    var name: String
    var cycleDays: Int?
    var memo: String
    /// 新規登録時の最初の購入日。nil なら未購入として登録する。
    var initialPurchaseDate: Date?

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedMemo: String {
        memo.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var nameIssue: NameIssue? {
        if trimmedName.isEmpty { return .empty }
        if trimmedName.count > ItemRules.nameMaxLength { return .tooLong }
        return nil
    }

    var cycleIssue: CycleIssue? {
        guard let cycleDays else { return .missing }
        return ItemRules.cycleDaysRange.contains(cycleDays) ? nil : .outOfRange
    }

    var isValid: Bool {
        nameIssue == nil && cycleIssue == nil
    }

    /// 周期の入力文字列を数値にする。数字以外が含まれていれば nil。
    static func parseCycleDays(_ text: String) -> Int? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, trimmed.allSatisfy(\.isASCIIDigit) else { return nil }
        return Int(trimmed)
    }
}

private extension Character {
    nonisolated var isASCIIDigit: Bool {
        isASCII && isNumber
    }
}
