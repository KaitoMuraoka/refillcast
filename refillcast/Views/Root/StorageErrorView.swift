import SwiftUI

/// データの保存先を用意できなかったときの画面。
struct StorageErrorView: View {
    var body: some View {
        ContentUnavailableView(
            "データを読み込めませんでした",
            systemImage: "exclamationmark.triangle",
            description: Text("アプリを再起動してください。解決しない場合は、端末の空き容量を確認してください。")
        )
    }
}

#Preview {
    StorageErrorView()
}
