import Foundation
import SwiftData

/// アプリ全体で共有するオブジェクトをまとめて作る。
@MainActor
final class AppDependencies {
    let container: ModelContainer
    let store: ItemStore
    let itemListViewModel: ItemListViewModel

    init(container: ModelContainer, reminders: any ReminderScheduling) {
        self.container = container
        self.store = ItemStore(context: container.mainContext, reminders: reminders)
        self.itemListViewModel = ItemListViewModel(store: store)
    }

    /// 端末に保存する、本番用の構成。
    static func live() throws -> AppDependencies {
        AppDependencies(
            container: try ModelContainerFactory.make(),
            reminders: NoopReminderScheduler()
        )
    }
}
