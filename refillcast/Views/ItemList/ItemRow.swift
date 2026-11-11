import SwiftUI

/// 一覧の 1 行。
struct ItemRow: View {
    let row: ItemRowModel
    let onPurchase: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: row.status.symbolName)
                .font(.title2)
                .foregroundStyle(row.status.tint)

            VStack(alignment: .leading, spacing: 2) {
                Text(row.name)
                    .font(.body.weight(.semibold))
                    .lineLimit(2)
                HStack(spacing: 6) {
                    Text(row.remainingText)
                        .fontWeight(.medium)
                        .foregroundStyle(row.status.tint)
                    if let dueDateText = row.dueDateText {
                        Text(dueDateText)
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.subheadline)
                .monospacedDigit()
            }

            Spacer(minLength: 8)

            Button("買った", action: onPurchase)
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    List {
        ItemRow(
            row: ItemRowModel(id: UUID(), name: "歯ブラシ", status: .overdue, remainingText: "3日超過", dueDateText: "11月8日"),
            onPurchase: {}
        )
        ItemRow(
            row: ItemRowModel(id: UUID(), name: "コンタクトレンズ", status: .soon, remainingText: "あと5日", dueDateText: "11月16日"),
            onPurchase: {}
        )
        ItemRow(
            row: ItemRowModel(id: UUID(), name: "浄水器カートリッジ", status: .plenty, remainingText: "あと70日", dueDateText: "2027年1月20日"),
            onPurchase: {}
        )
        ItemRow(
            row: ItemRowModel(id: UUID(), name: "シャンプー", status: .notPurchased, remainingText: "未購入", dueDateText: nil),
            onPurchase: {}
        )
    }
}
