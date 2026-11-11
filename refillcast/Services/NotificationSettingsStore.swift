import Foundation
import Observation

/// 通知の設定。UserDefaults に保存する。
@MainActor
@Observable
final class NotificationSettingsStore {
    private enum Keys {
        static let isEnabled = "notification.isEnabled"
        static let hour = "notification.hour"
        static let minute = "notification.minute"
        static let leadTime = "notification.leadTimeDays"
    }

    var isEnabled: Bool {
        didSet { defaults.set(isEnabled, forKey: Keys.isEnabled) }
    }

    var time: ReminderTime {
        didSet {
            defaults.set(time.hour, forKey: Keys.hour)
            defaults.set(time.minute, forKey: Keys.minute)
        }
    }

    var leadTime: ReminderLeadTime {
        didSet { defaults.set(leadTime.rawValue, forKey: Keys.leadTime) }
    }

    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.isEnabled = defaults.object(forKey: Keys.isEnabled) as? Bool ?? true
        let hour = defaults.object(forKey: Keys.hour) as? Int ?? ReminderTime.defaultTime.hour
        let minute = defaults.object(forKey: Keys.minute) as? Int ?? ReminderTime.defaultTime.minute
        self.time = ReminderTime(hour: hour, minute: minute)
        let leadTimeDays = defaults.object(forKey: Keys.leadTime) as? Int ?? ReminderLeadTime.sameDay.rawValue
        self.leadTime = ReminderLeadTime(rawValue: leadTimeDays) ?? .sameDay
    }
}
