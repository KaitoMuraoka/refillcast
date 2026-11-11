import Foundation
import Testing
@testable import refillcast

struct ItemOrderingTests {
    private func day(_ month: Int, _ day: Int) -> Date {
        TestCalendar.date(2026, month, day, 0)
    }

    private func key(_ name: String, due: Date?, created: Date = TestCalendar.date(2026, 1, 1)) -> ItemSortKey {
        ItemSortKey(dueDay: due, name: name, createdAt: created)
    }

    @Test func sortsByDueDayAscending() {
        let keys = [
            key("C", due: day(12, 1)),
            key("A", due: day(11, 5)),   // 期限超過（いちばん古い）
            key("B", due: day(11, 20)),
        ]
        let sorted = ItemOrdering.sorted(keys) { $0 }
        #expect(sorted.map(\.name) == ["A", "B", "C"])
    }

    @Test func notPurchasedGoesLastInCreationOrder() {
        let keys = [
            key("未購入2", due: nil, created: TestCalendar.date(2026, 3, 1)),
            key("予定あり", due: day(12, 31)),
            key("未購入1", due: nil, created: TestCalendar.date(2026, 2, 1)),
        ]
        let sorted = ItemOrdering.sorted(keys) { $0 }
        #expect(sorted.map(\.name) == ["予定あり", "未購入1", "未購入2"])
    }

    @Test func sameDueDaySortsByName() {
        let keys = [
            key("歯ブラシ", due: day(11, 20)),
            key("洗剤", due: day(11, 20)),
            key("コンタクト", due: day(11, 20)),
        ]
        let sorted = ItemOrdering.sorted(keys) { $0 }
        let expected = keys.map(\.name).sorted { $0.localizedStandardCompare($1) == .orderedAscending }
        #expect(sorted.map(\.name) == expected)
    }
}
