import Foundation
import Testing
@testable import refillcast

@MainActor
struct ItemListViewModelTests {
    @Test func rowsAreSortedByDueDay() throws {
        let fixture = try StoreFixture()
        fixture.store.addItem(fixture.draft("余裕", cycleDays: 60, purchasedAt: TestCalendar.date(2026, 11, 1)))
        fixture.store.addItem(fixture.draft("未購入"))
        fixture.store.addItem(fixture.draft("超過", cycleDays: 7, purchasedAt: TestCalendar.date(2026, 11, 1)))
        fixture.store.addItem(fixture.draft("そろそろ", cycleDays: 14, purchasedAt: TestCalendar.date(2026, 11, 1)))

        let viewModel = ItemListViewModel(store: fixture.store)

        #expect(viewModel.rows.map(\.name) == ["超過", "そろそろ", "余裕", "未購入"])
        #expect(viewModel.rows.map(\.remainingText) == ["3日超過", "あと4日", "あと50日", "未購入"])
        #expect(viewModel.rows.map(\.status) == [.overdue, .soon, .plenty, .notPurchased])
    }

    @Test func markPurchasedReordersRowsAndOffersUndo() throws {
        let fixture = try StoreFixture()
        let overdue = try #require(fixture.store.addItem(
            fixture.draft("超過", cycleDays: 7, purchasedAt: TestCalendar.date(2026, 11, 1))
        ))
        // 11/1 + 15日 = 11/16（あと5日）
        fixture.store.addItem(fixture.draft("そろそろ", cycleDays: 15, purchasedAt: TestCalendar.date(2026, 11, 1)))
        let viewModel = ItemListViewModel(store: fixture.store)
        #expect(viewModel.rows.map(\.name) == ["超過", "そろそろ"])

        viewModel.markPurchased(overdue.uuid)

        // 超過していた品目は 11/11 + 7日 = 11/18 になり、11/16 の品目より後ろへ移る。
        #expect(viewModel.rows.map(\.name) == ["そろそろ", "超過"])
        #expect(viewModel.rows.last?.remainingText == "あと7日")
        #expect(viewModel.undo?.itemID == overdue.uuid)
        #expect(fixture.reminders.rescheduled.last?.itemID == overdue.uuid)

        viewModel.undoLastPurchase()

        #expect(viewModel.undo == nil)
        #expect(viewModel.rows.first?.name == "超過")
        #expect(overdue.purchases.count == 1)
    }

    @Test func confirmDeletionRemovesRow() throws {
        let fixture = try StoreFixture()
        let item = try #require(fixture.store.addItem(fixture.draft("歯ブラシ", purchasedAt: fixture.now)))
        let viewModel = ItemListViewModel(store: fixture.store)

        viewModel.requestDeletion(item.uuid)
        #expect(viewModel.isDeleteConfirmationPresented)

        viewModel.confirmDeletion(of: item.uuid)

        #expect(!viewModel.isDeleteConfirmationPresented)
        #expect(viewModel.rows.isEmpty)
    }
}

@MainActor
struct ItemListEmptyStateTests {
    @Test func emptyUntilFirstItem() throws {
        let fixture = try StoreFixture()
        let viewModel = ItemListViewModel(store: fixture.store)
        #expect(viewModel.isEmpty)
        #expect(!viewModel.isErrorPresented)

        fixture.store.addItem(fixture.draft("歯ブラシ"))

        #expect(!viewModel.isEmpty)
    }
}
