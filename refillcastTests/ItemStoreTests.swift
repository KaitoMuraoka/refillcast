import Foundation
import SwiftData
import Testing
@testable import refillcast

@MainActor
struct ItemStoreTests {
    @Test func addItemWithInitialPurchase() throws {
        let fixture = try StoreFixture()
        let item = try #require(fixture.store.addItem(fixture.draft(" 歯ブラシ ", purchasedAt: fixture.now)))

        #expect(item.name == "歯ブラシ")
        #expect(item.purchases.count == 1)
        #expect(fixture.store.items.count == 1)
        #expect(fixture.store.forecast(for: item).remainingDays == 30)
    }

    @Test func addItemWithoutPurchaseIsNotPurchased() throws {
        let fixture = try StoreFixture()
        let item = try #require(fixture.store.addItem(fixture.draft("洗剤")))
        #expect(item.purchases.isEmpty)
        #expect(fixture.store.forecast(for: item).status == .notPurchased)
    }

    @Test func invalidDraftIsNotSaved() throws {
        let fixture = try StoreFixture()
        #expect(fixture.store.addItem(fixture.draft("", cycleDays: 30)) == nil)
        #expect(fixture.store.addItem(fixture.draft("洗剤", cycleDays: 0)) == nil)
        #expect(fixture.store.items.isEmpty)
    }

    @Test func addingItemRequestsAuthorizationAndSchedulesReminder() throws {
        let fixture = try StoreFixture()
        let item = try #require(fixture.store.addItem(fixture.draft("歯ブラシ", purchasedAt: fixture.now)))

        #expect(fixture.reminders.authorizationRequestCount == 1)
        #expect(fixture.reminders.rescheduled.last?.itemID == item.uuid)
        #expect(fixture.reminders.rescheduled.last?.dueDay == TestCalendar.date(2026, 12, 11, 0))
    }

    @Test func recordPurchaseUpdatesForecastAndReminder() throws {
        let fixture = try StoreFixture()
        let item = try #require(fixture.store.addItem(
            fixture.draft("歯ブラシ", cycleDays: 30, purchasedAt: TestCalendar.date(2026, 10, 1))
        ))
        #expect(fixture.store.forecast(for: item).remainingDays == -11)

        fixture.store.recordPurchase(for: item)

        #expect(item.purchases.count == 2)
        #expect(fixture.store.forecast(for: item).remainingDays == 30)
        #expect(fixture.reminders.rescheduled.last?.dueDay == TestCalendar.date(2026, 12, 11, 0))
    }

    @Test func deletePurchaseRestoresPreviousForecast() throws {
        let fixture = try StoreFixture()
        let item = try #require(fixture.store.addItem(
            fixture.draft("歯ブラシ", cycleDays: 30, purchasedAt: TestCalendar.date(2026, 10, 1))
        ))
        let purchase = try #require(fixture.store.recordPurchase(for: item))

        fixture.store.deletePurchase(purchase)

        #expect(item.purchases.count == 1)
        #expect(fixture.store.forecast(for: item).remainingDays == -11)
        #expect(try fixture.container.mainContext.fetchCount(FetchDescriptor<Purchase>()) == 1)
    }

    @Test func updateItemReschedulesReminder() throws {
        let fixture = try StoreFixture()
        let item = try #require(fixture.store.addItem(fixture.draft("歯ブラシ", purchasedAt: fixture.now)))

        let updated = fixture.store.updateItem(item, with: fixture.draft("電動歯ブラシ", cycleDays: 90))

        #expect(updated)
        #expect(item.name == "電動歯ブラシ")
        #expect(item.cycleDays == 90)
        #expect(fixture.reminders.rescheduled.last?.name == "電動歯ブラシ")
    }

    @Test func deleteItemCancelsReminderAndPurchases() throws {
        let fixture = try StoreFixture()
        let item = try #require(fixture.store.addItem(fixture.draft("歯ブラシ", purchasedAt: fixture.now)))
        let itemID = item.uuid

        fixture.store.deleteItem(item)

        #expect(fixture.store.items.isEmpty)
        #expect(fixture.reminders.cancelled == [itemID])
        #expect(try fixture.container.mainContext.fetchCount(FetchDescriptor<Purchase>()) == 0)
    }

    @Test func dataSurvivesNewContext() throws {
        let fixture = try StoreFixture()
        fixture.store.addItem(fixture.draft("歯ブラシ", purchasedAt: fixture.now))

        let otherContext = ModelContext(fixture.container)
        let items = try otherContext.fetch(FetchDescriptor<Item>())
        #expect(items.map(\.name) == ["歯ブラシ"])
        #expect(items.first?.purchases.count == 1)
    }
}
