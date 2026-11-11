import Foundation
import Observation

/// 設定画面の ViewModel。
@MainActor
@Observable
final class SettingsViewModel: Identifiable {
    @ObservationIgnored private let settings: NotificationSettingsStore
    @ObservationIgnored private let reminders: ReminderService
    @ObservationIgnored private let store: ItemStore

    init(settings: NotificationSettingsStore, reminders: ReminderService, store: ItemStore) {
        self.settings = settings
        self.reminders = reminders
        self.store = store
    }

    // MARK: - 設定

    var isNotificationEnabled: Bool {
        get { settings.isEnabled }
        set {
            guard settings.isEnabled != newValue else { return }
            settings.isEnabled = newValue
            store.rescheduleAllReminders()
        }
    }

    /// 通知する時刻。DatePicker で扱えるよう、今日の日付に時刻を合わせた Date にする。
    var reminderTime: Date {
        get {
            let time = settings.time
            return store.calendar.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: store.today)
                ?? store.today
        }
        set {
            let components = store.calendar.dateComponents([.hour, .minute], from: newValue)
            let time = ReminderTime(hour: components.hour ?? 0, minute: components.minute ?? 0)
            guard settings.time != time else { return }
            settings.time = time
            store.rescheduleAllReminders()
        }
    }

    var leadTime: ReminderLeadTime {
        get { settings.leadTime }
        set {
            guard settings.leadTime != newValue else { return }
            settings.leadTime = newValue
            store.rescheduleAllReminders()
        }
    }

    var leadTimeOptions: [ReminderLeadTime] {
        ReminderLeadTime.allCases
    }

    func label(for leadTime: ReminderLeadTime) -> String {
        switch leadTime {
        case .sameDay: String(localized: "当日")
        case .oneDayBefore: String(localized: "1日前")
        case .threeDaysBefore: String(localized: "3日前")
        }
    }

    // MARK: - 通知の許可

    /// 通知が許可されていないときに、設定アプリへの案内を出す。
    var showsPermissionDeniedGuidance: Bool {
        reminders.authorization == .denied
    }

    /// まだ許可を求めていないときの説明を出す。
    var showsPermissionPendingNote: Bool {
        reminders.authorization == .notDetermined
    }

    var notificationSettingsURL: URL? {
        SystemSettingsLink.notificationSettingsURL
    }

    func refreshAuthorization() async {
        await reminders.refreshAuthorization()
    }
}
