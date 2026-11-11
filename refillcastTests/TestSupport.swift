import Foundation
import SwiftData
@testable import refillcast

/// 通知の予約を記録するだけの偽物。
@MainActor
final class RecordingReminderScheduler: ReminderScheduling {
    private(set) var authorizationRequestCount = 0
    private(set) var rescheduled: [ReminderSource] = []
    private(set) var rescheduledAll: [[ReminderSource]] = []
    private(set) var cancelled: [UUID] = []

    func requestAuthorizationIfNeeded() { authorizationRequestCount += 1 }
    func reschedule(_ source: ReminderSource) { rescheduled.append(source) }
    func rescheduleAll(_ sources: [ReminderSource]) { rescheduledAll.append(sources) }
    func cancel(itemID: UUID) { cancelled.append(itemID) }
}

/// インメモリの ItemStore と、時刻を差し替えられる時計。
@MainActor
final class StoreFixture {
    let container: ModelContainer
    let reminders = RecordingReminderScheduler()
    var now: Date
    private(set) var store: ItemStore!

    init(now: Date = TestCalendar.date(2026, 11, 11, 10)) throws {
        self.now = now
        self.container = try ModelContainerFactory.make(inMemory: true)
        self.store = ItemStore(
            context: container.mainContext,
            reminders: reminders,
            calendar: TestCalendar.tokyo,
            now: { [unowned self] in self.now }
        )
    }

    func draft(
        _ name: String,
        cycleDays: Int = 30,
        purchasedAt: Date? = nil
    ) -> ItemDraft {
        ItemDraft(name: name, cycleDays: cycleDays, memo: "", initialPurchaseDate: purchasedAt)
    }
}

/// 通知の予約を記録する偽の NotificationClient。
@MainActor
final class FakeNotificationClient: NotificationClient {
    var status: NotificationAuthorization
    var grantsOnRequest: Bool
    private(set) var requestCount = 0
    private(set) var pending: [String: ScheduledNotification] = [:]

    init(status: NotificationAuthorization = .authorized, grantsOnRequest: Bool = true) {
        self.status = status
        self.grantsOnRequest = grantsOnRequest
    }

    func authorizationStatus() async -> NotificationAuthorization { status }

    func requestAuthorization() async -> Bool {
        requestCount += 1
        status = grantsOnRequest ? .authorized : .denied
        return grantsOnRequest
    }

    func add(_ notification: ScheduledNotification) async {
        pending[notification.identifier] = notification
    }

    func removePending(identifiers: [String]) {
        identifiers.forEach { pending[$0] = nil }
    }

    func removeAllPending() {
        pending.removeAll()
    }
}

/// 実物の ReminderService と ItemStore を、偽の NotificationClient でつないだもの。
@MainActor
final class NotificationFixture {
    let container: ModelContainer
    let client: FakeNotificationClient
    let settings: NotificationSettingsStore
    let reminders: ReminderService
    let store: ItemStore
    let now: Date

    init(status: NotificationAuthorization = .authorized, grantsOnRequest: Bool = true) throws {
        let now = TestCalendar.date(2026, 11, 11, 10)
        self.now = now
        container = try ModelContainerFactory.make(inMemory: true)
        client = FakeNotificationClient(status: status, grantsOnRequest: grantsOnRequest)
        settings = NotificationSettingsStore(defaults: UserDefaults(suiteName: UUID().uuidString)!)
        reminders = ReminderService(client: client, settings: settings, calendar: TestCalendar.tokyo, now: { now })
        store = ItemStore(context: container.mainContext, reminders: reminders, calendar: TestCalendar.tokyo, now: { now })
    }

    @discardableResult
    func addItem(_ name: String, cycleDays: Int = 30, purchasedAt: Date?) -> Item? {
        store.addItem(ItemDraft(name: name, cycleDays: cycleDays, memo: "", initialPurchaseDate: purchasedAt))
    }

    func notification(for item: Item) -> ScheduledNotification? {
        client.pending[ReminderService.identifier(for: item.uuid)]
    }
}
