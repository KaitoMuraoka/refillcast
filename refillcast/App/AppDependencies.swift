import Foundation
import SwiftData

/// アプリ全体で共有するオブジェクトをまとめて作る。
@MainActor
final class AppDependencies {
    let container: ModelContainer
    let notificationSettings: NotificationSettingsStore
    let reminderService: ReminderService
    let store: ItemStore
    let settingsViewModel: SettingsViewModel
    let itemListViewModel: ItemListViewModel

    init(container: ModelContainer, notificationClient: any NotificationClient, defaults: UserDefaults) {
        self.container = container
        self.notificationSettings = NotificationSettingsStore(defaults: defaults)
        self.reminderService = ReminderService(client: notificationClient, settings: notificationSettings)
        self.store = ItemStore(context: container.mainContext, reminders: reminderService)
        self.settingsViewModel = SettingsViewModel(
            settings: notificationSettings,
            reminders: reminderService,
            store: store
        )
        self.itemListViewModel = ItemListViewModel(store: store, settingsViewModel: settingsViewModel)
    }

    /// 端末に保存し、実際に通知を予約する本番用の構成。
    static func live() throws -> AppDependencies {
        AppDependencies(
            container: try ModelContainerFactory.make(),
            notificationClient: SystemNotificationClient(),
            defaults: .standard
        )
    }
}
