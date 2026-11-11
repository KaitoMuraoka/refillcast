import Foundation
import Testing
@testable import refillcast

@MainActor
struct ItemDetailViewModelTests {
    @Test func showsForecastAndHistoryNewestFirst() throws {
        let fixture = try StoreFixture()
        let item = try #require(fixture.store.addItem(
            fixture.draft("歯ブラシ", cycleDays: 30, purchasedAt: TestCalendar.date(2026, 9, 1))
        ))
        fixture.store.recordPurchase(for: item, on: TestCalendar.date(2026, 10, 20))
        fixture.store.recordPurchase(for: item, on: TestCalendar.date(2026, 10, 1))

        let viewModel = ItemDetailViewModel(itemID: item.uuid, store: fixture.store)

        #expect(viewModel.name == "歯ブラシ")
        #expect(viewModel.cycleText == "30日ごと")
        // 10/20 + 30日 = 11/19。今日は 11/11 なので、あと8日。
        #expect(viewModel.remainingText == "あと8日")
        #expect(viewModel.status == .plenty)
        #expect(viewModel.purchaseRows.map(\.dateText) == [
            ForecastText.longDate(TestCalendar.date(2026, 10, 20)),
            ForecastText.longDate(TestCalendar.date(2026, 10, 1)),
            ForecastText.longDate(TestCalendar.date(2026, 9, 1)),
        ])
    }

    @Test func addPastPurchase() throws {
        let fixture = try StoreFixture()
        let item = try #require(fixture.store.addItem(fixture.draft("洗剤", cycleDays: 10)))
        let viewModel = ItemDetailViewModel(itemID: item.uuid, store: fixture.store)
        #expect(!viewModel.hasPurchases)

        viewModel.startAddingPurchase()
        viewModel.newPurchaseDate = TestCalendar.date(2026, 11, 5)
        viewModel.addPurchase()

        #expect(!viewModel.isAddingPurchase)
        #expect(viewModel.hasPurchases)
        #expect(viewModel.remainingText == "あと4日")
        #expect(fixture.reminders.rescheduled.last?.itemID == item.uuid)
    }

    @Test func futurePurchaseDateIsClampedToToday() throws {
        let fixture = try StoreFixture()
        let item = try #require(fixture.store.addItem(fixture.draft("洗剤", cycleDays: 10)))
        let viewModel = ItemDetailViewModel(itemID: item.uuid, store: fixture.store)

        viewModel.newPurchaseDate = TestCalendar.date(2026, 12, 1)
        viewModel.addPurchase()

        #expect(viewModel.remainingText == "あと10日")
    }

    @Test func deletePurchaseByOffset() throws {
        let fixture = try StoreFixture()
        let item = try #require(fixture.store.addItem(
            fixture.draft("歯ブラシ", cycleDays: 30, purchasedAt: TestCalendar.date(2026, 9, 1))
        ))
        fixture.store.recordPurchase(for: item, on: TestCalendar.date(2026, 10, 20))
        let viewModel = ItemDetailViewModel(itemID: item.uuid, store: fixture.store)

        // 先頭（いちばん新しい 10/20）を削除する。
        viewModel.deletePurchases(at: IndexSet(integer: 0))

        #expect(viewModel.purchaseRows.count == 1)
        #expect(viewModel.lastPurchaseText == ForecastText.longDate(TestCalendar.date(2026, 9, 1, 0)))
    }

    @Test func deletedItemIsUnavailable() throws {
        let fixture = try StoreFixture()
        let item = try #require(fixture.store.addItem(fixture.draft("歯ブラシ")))
        let viewModel = ItemDetailViewModel(itemID: item.uuid, store: fixture.store)

        fixture.store.deleteItem(item)

        #expect(!viewModel.isAvailable)
    }
}
