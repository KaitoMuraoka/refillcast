import Foundation

/// 一覧の 1 行に表示する内容。
nonisolated struct ItemRowModel: Identifiable, Equatable, Sendable {
    let id: UUID
    let name: String
    let status: ReplacementStatus
    /// 「あと5日」「3日超過」など。
    let remainingText: String
    /// 「11月16日」など。未購入なら nil。
    let dueDateText: String?
}
