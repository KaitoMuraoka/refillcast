import Foundation
import Observation

/// 品目ごとのローカル通知を予約する。
///
/// 操作は受け付けた順に 1 つずつ実行する（「買った」と取り消しを続けて押しても順番が入れ替わらない）。
@MainActor
@Observable
final class ReminderService: ReminderScheduling {
    /// 直近に確認した通知の許可の状態。
    private(set) var authorization: NotificationAuthorization = .notDetermined

    @ObservationIgnored private let client: any NotificationClient
    @ObservationIgnored private let settings: NotificationSettingsStore
    @ObservationIgnored private let calendar: Calendar
    @ObservationIgnored private let now: () -> Date
    @ObservationIgnored private var lastOperation: Task<Void, Never>?

    init(
        client: any NotificationClient,
        settings: NotificationSettingsStore,
        calendar: Calendar = .current,
        now: @escaping () -> Date = { Date.now }
    ) {
        self.client = client
        self.settings = settings
        self.calendar = calendar
        self.now = now
    }

    static func identifier(for itemID: UUID) -> String {
        "item-\(itemID.uuidString)"
    }

    // MARK: - ReminderScheduling

    func requestAuthorizationIfNeeded() {
        enqueue { service in
            let status = await service.client.authorizationStatus()
            guard status == .notDetermined else {
                service.authorization = status
                return
            }
            _ = await service.client.requestAuthorization()
            service.authorization = await service.client.authorizationStatus()
        }
    }

    func reschedule(_ source: ReminderSource) {
        enqueue { service in
            service.client.removePending(identifiers: [ReminderService.identifier(for: source.itemID)])
            guard await service.canSchedule() else { return }
            if let notification = service.makeNotification(for: source) {
                await service.client.add(notification)
            }
        }
    }

    func rescheduleAll(_ sources: [ReminderSource]) {
        enqueue { service in
            service.client.removeAllPending()
            guard await service.canSchedule() else { return }
            for source in sources {
                if let notification = service.makeNotification(for: source) {
                    await service.client.add(notification)
                }
            }
        }
    }

    func cancel(itemID: UUID) {
        enqueue { service in
            service.client.removePending(identifiers: [ReminderService.identifier(for: itemID)])
        }
    }

    // MARK: - 許可の状態

    func refreshAuthorization() async {
        authorization = await client.authorizationStatus()
    }

    /// 受け付けた操作がすべて終わるまで待つ（テスト用）。
    func waitUntilIdle() async {
        while let operation = lastOperation {
            await operation.value
            if lastOperation == operation {
                return
            }
        }
    }

    // MARK: - 内部

    func makeNotification(for source: ReminderSource) -> ScheduledNotification? {
        guard let dueDay = source.dueDay,
              let plan = ReminderPlanner.plan(
                  dueDay: dueDay,
                  leadTime: settings.leadTime,
                  time: settings.time,
                  now: now(),
                  calendar: calendar
              )
        else { return nil }

        let body = plan.daysBefore == 0
            ? String(localized: "\(source.name)の買い替え時期です")
            : String(localized: "\(source.name)の買い替え時期まであと\(plan.daysBefore)日です")
        return ScheduledNotification(
            identifier: ReminderService.identifier(for: source.itemID),
            title: String(localized: "買い替えのお知らせ"),
            body: body,
            dateComponents: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: plan.fireDate)
        )
    }

    private func canSchedule() async -> Bool {
        guard settings.isEnabled else { return false }
        authorization = await client.authorizationStatus()
        return authorization == .authorized
    }

    private func enqueue(_ operation: @escaping @MainActor (ReminderService) async -> Void) {
        let previous = lastOperation
        lastOperation = Task { [self] in
            await previous?.value
            await operation(self)
        }
    }
}
