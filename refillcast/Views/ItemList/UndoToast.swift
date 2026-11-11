import SwiftUI

/// 「買った」の直後に画面下部に出す、取り消し用のトースト。
///
/// 操作部品の層に置くので Liquid Glass（glassEffect）を使う。
struct UndoToast: View {
    let message: String
    let onUndo: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text(message)
                .font(.subheadline)
                .lineLimit(2)
            Spacer(minLength: 8)
            Button("取り消す", action: onUndo)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .frame(maxWidth: 520)
        .glassEffect(.regular.interactive(), in: .capsule)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

#Preview {
    VStack {
        Spacer()
        UndoToast(message: "「歯ブラシ」を購入済みにしました", onUndo: {})
    }
}
