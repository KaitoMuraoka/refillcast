import Foundation
import UserNotifications

/// 通知の許可の状態。
nonisolated enum NotificationAuthorization: Equatable, Sendable {
    case notDetermined
    case denied
    case authorized
}

/// 予約する通知の内容。
nonisolated struct ScheduledNotification: Equatable, Sendable {
    let identifier: String
    let title: String
    let body: String
    let dateComponents: DateComponents
}

/// UserNotifications への窓口。テストやプレビューでは偽物に差し替える。
@MainActor
protocol NotificationClient {
    func authorizationStatus() async -> NotificationAuthorization
    func requestAuthorization() async -> Bool
    func add(_ notification: ScheduledNotification) async
    func removePending(identifiers: [String])
    func removeAllPending()
}

/// UNUserNotificationCenter を使う実装。
struct SystemNotificationClient: NotificationClient {
    func authorizationStatus() async -> NotificationAuthorization {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            return .notDetermined
        case .authorized, .provisional, .ephemeral:
            return .authorized
        case .denied:
            return .denied
        @unknown default:
            return .denied
        }
    }

    func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        } catch {
            return false
        }
    }

    func add(_ notification: ScheduledNotification) async {
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.body
        content.sound = .default
        let trigger = UNCalendarNotificationTrigger(dateMatching: notification.dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: notification.identifier, content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
    }

    func removePending(identifiers: [String]) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    func removeAllPending() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}

/// プレビュー用。何も予約せず、指定した許可の状態を返す。
struct PreviewNotificationClient: NotificationClient {
    var status: NotificationAuthorization = .authorized

    func authorizationStatus() async -> NotificationAuthorization { status }
    func requestAuthorization() async -> Bool { status == .authorized }
    func add(_ notification: ScheduledNotification) async {}
    func removePending(identifiers: [String]) {}
    func removeAllPending() {}
}
