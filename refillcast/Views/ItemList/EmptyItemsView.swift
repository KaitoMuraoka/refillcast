import SwiftUI

/// 品目が 1 件もないときの表示。
struct EmptyItemsView: View {
    let onAdd: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("品目がありません", systemImage: "shippingbox")
        } description: {
            Text("歯ブラシや洗剤などの消耗品を登録すると、次の買い替え時期をお知らせします。")
        } actions: {
            Button("品目を登録", systemImage: "plus", action: onAdd)
                .buttonStyle(.glassProminent)
        }
    }
}

#Preview {
    EmptyItemsView(onAdd: {})
}
