import Foundation
import Testing
@testable import refillcast

@MainActor
struct ReminderServiceTests {
    @Test func firstItemRequestsAuthorizationThenSchedules() async throws {
        let fixture = try NotificationFixture(status: .notDetermined)
        let item = try #require(fixture.addItem("歯ブラシ", purchasedAt: fixture.now))
        await fixture.reminders.waitUntilIdle()

        #expect(fixture.client.requestCount == 1)
        #expect(fixture.reminders.authorization == .authorized)
        let notification = try #require(fixture.notification(for: item))
        #expect(notification.body == "歯ブラシの買い替え時期です")
        // 11/11 + 30日 = 12/11 の 9:00
        #expect(notification.dateComponents.month == 12)
        #expect(notification.dateComponents.day == 11)
        #expect(notification.dateComponents.hour == 9)
        #expect(notification.dateComponents.minute == 0)
    }

    @Test func authorizationIsRequestedOnlyOnce() async throws {
        let fixture = try NotificationFixture(status: .notDetermined)
        fixture.addItem("歯ブラシ", purchasedAt: fixture.now)
        fixture.addItem("洗剤", purchasedAt: fixture.now)
        await fixture.reminders.waitUntilIdle()

        #expect(fixture.client.requestCount == 1)
    }

    @Test func deniedAuthorizationDoesNotScheduleButAppWorks() async throws {
        let fixture = try NotificationFixture(status: .notDetermined, grantsOnRequest: false)
        let item = try #require(fixture.addItem("歯ブラシ", purchasedAt: fixture.now))
        await fixture.reminders.waitUntilIdle()

        #expect(fixture.reminders.authorization == .denied)
        #expect(fixture.client.pending.isEmpty)
        #expect(fixture.store.items.count == 1)
        #expect(fixture.store.forecast(for: item).remainingDays == 30)
    }

    @Test func purchaseMovesNotification() async throws {
        let fixture = try NotificationFixture()
        let item = try #require(fixture.addItem("歯ブラシ", cycleDays: 30, purchasedAt: TestCalendar.date(2026, 10, 25)))
        await fixture.reminders.waitUntilIdle()
        #expect(fixture.notification(for: item)?.dateComponents.day == 24)

        fixture.store.recordPurchase(for: item)
        await fixture.reminders.waitUntilIdle()

        #expect(fixture.notification(for: item)?.dateComponents.month == 12)
        #expect(fixture.notification(for: item)?.dateComponents.day == 11)
    }

    @Test func purchaseAndUndoKeepOrder() async throws {
        let fixture = try NotificationFixture()
        let item = try #require(fixture.addItem("歯ブラシ", cycleDays: 30, purchasedAt: TestCalendar.date(2026, 10, 25)))
        let viewModel = ItemListViewModel(store: fixture.store)

        viewModel.markPurchased(item.uuid)
        viewModel.undoLastPurchase()
        await fixture.reminders.waitUntilIdle()

        #expect(fixture.notification(for: item)?.dateComponents.month == 11)
        #expect(fixture.notification(for: item)?.dateComponents.day == 24)
    }

    @Test func deletingItemCancelsNotification() async throws {
        let fixture = try NotificationFixture()
        let item = try #require(fixture.addItem("歯ブラシ", purchasedAt: fixture.now))
        await fixture.reminders.waitUntilIdle()
        #expect(fixture.client.pending.count == 1)

        fixture.store.deleteItem(item)
        await fixture.reminders.waitUntilIdle()

        #expect(fixture.client.pending.isEmpty)
    }

    @Test func notPurchasedOrOverdueItemsAreNotScheduled() async throws {
        let fixture = try NotificationFixture()
        fixture.addItem("未購入", purchasedAt: nil)
        fixture.addItem("超過", cycleDays: 7, purchasedAt: TestCalendar.date(2026, 10, 1))
        await fixture.reminders.waitUntilIdle()

        #expect(fixture.client.pending.isEmpty)
    }

    @Test func leadTimeChangesBody() async throws {
        let fixture = try NotificationFixture()
        fixture.settings.leadTime = .threeDaysBefore
        let item = try #require(fixture.addItem("歯ブラシ", purchasedAt: fixture.now))
        await fixture.reminders.waitUntilIdle()

        let notification = try #require(fixture.notification(for: item))
        #expect(notification.body == "歯ブラシの買い替え時期まであと3日です")
        #expect(notification.dateComponents.day == 8)
    }

    @Test func disablingNotificationsRemovesAll() async throws {
        let fixture = try NotificationFixture()
        fixture.addItem("歯ブラシ", purchasedAt: fixture.now)
        await fixture.reminders.waitUntilIdle()
        let viewModel = SettingsViewModel(settings: fixture.settings, reminders: fixture.reminders, store: fixture.store)

        viewModel.isNotificationEnabled = false
        await fixture.reminders.waitUntilIdle()
        #expect(fixture.client.pending.isEmpty)

        viewModel.isNotificationEnabled = true
        await fixture.reminders.waitUntilIdle()
        #expect(fixture.client.pending.count == 1)
    }

    @Test func changingTimeReschedules() async throws {
        let fixture = try NotificationFixture()
        let item = try #require(fixture.addItem("歯ブラシ", purchasedAt: fixture.now))
        let viewModel = SettingsViewModel(settings: fixture.settings, reminders: fixture.reminders, store: fixture.store)

        viewModel.reminderTime = TestCalendar.date(2026, 11, 11, 20, 15)
        await fixture.reminders.waitUntilIdle()

        #expect(fixture.notification(for: item)?.dateComponents.hour == 20)
        #expect(fixture.notification(for: item)?.dateComponents.minute == 15)
    }
}

@MainActor
struct NotificationSettingsStoreTests {
    @Test func defaults() {
        let settings = NotificationSettingsStore(defaults: UserDefaults(suiteName: UUID().uuidString)!)
        #expect(settings.isEnabled)
        #expect(settings.time == ReminderTime(hour: 9, minute: 0))
        #expect(settings.leadTime == .sameDay)
    }

    @Test func valuesArePersisted() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let settings = NotificationSettingsStore(defaults: defaults)
        settings.isEnabled = false
        settings.time = ReminderTime(hour: 7, minute: 45)
        settings.leadTime = .oneDayBefore

        let reloaded = NotificationSettingsStore(defaults: defaults)
        #expect(!reloaded.isEnabled)
        #expect(reloaded.time == ReminderTime(hour: 7, minute: 45))
        #expect(reloaded.leadTime == .oneDayBefore)
    }
}
