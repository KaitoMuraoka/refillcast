import Foundation
import SwiftData
import Testing
@testable import refillcast

@MainActor
struct ModelTests {
    private func makeContext() throws -> ModelContext {
        ModelContext(try ModelContainerFactory.make(inMemory: true))
    }

    @Test func purchaseIsLinkedToItem() throws {
        let context = try makeContext()
        let item = Item(name: "歯ブラシ", cycleDays: 30)
        context.insert(item)
        item.purchases.append(Purchase(purchasedAt: .now))
        try context.save()

        let purchases = try context.fetch(FetchDescriptor<Purchase>())
        #expect(purchases.count == 1)
        #expect(purchases.first?.item?.uuid == item.uuid)
    }

    @Test func deletingItemDeletesPurchases() throws {
        let context = try makeContext()
        let item = Item(name: "洗剤", cycleDays: 45)
        context.insert(item)
        item.purchases.append(Purchase(purchasedAt: .now))
        item.purchases.append(Purchase(purchasedAt: .now.addingTimeInterval(-86_400)))
        try context.save()

        context.delete(item)
        try context.save()

        #expect(try context.fetchCount(FetchDescriptor<Item>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<Purchase>()) == 0)
    }
}
