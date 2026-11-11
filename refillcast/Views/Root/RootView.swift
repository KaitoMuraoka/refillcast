import SwiftData
import SwiftUI

/// アプリのルート。ステップ3で一覧画面に差し替える。
struct RootView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Refillcast",
                systemImage: "arrow.trianglehead.2.clockwise",
                description: Text("消耗品の買い替え時期を予報します")
            )
            .navigationTitle("Refillcast")
        }
    }
}

#Preview(traits: .sampleData) {
    RootView()
}
