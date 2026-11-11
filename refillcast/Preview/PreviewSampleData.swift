import Foundation
import SwiftData

extension AppDependencies {
    /// プレビュー用の構成。端末には保存せず、通知も予約しない。
    static func preview(withSampleData: Bool = true) -> AppDependencies {
        let container: ModelContainer
        do {
            container = try ModelContainerFactory.make(inMemory: true)
        } catch {
            fatalError("プレビュー用の ModelContainer を作れませんでした: \(error)")
        }
        if withSampleData {
            PreviewSampleData.insert(into: container.mainContext)
            try? container.mainContext.save()
        }
        return AppDependencies(container: container, reminders: NoopReminderScheduler())
    }
}

/// プレビュー用のサンプルデータ。
enum PreviewSampleData {
    private struct Seed {
        let name: String
        let cycleDays: Int
        /// 何日前に買ったか。空なら未購入。
        let daysAgo: [Int]
        let memo: String
    }

    private static let seeds: [Seed] = [
        Seed(name: "歯ブラシ", cycleDays: 30, daysAgo: [33, 63], memo: "やわらかめ"),
        Seed(name: "洗濯用洗剤", cycleDays: 45, daysAgo: [40, 88], memo: "詰め替え用"),
        Seed(name: "コンタクトレンズ", cycleDays: 14, daysAgo: [9], memo: ""),
        Seed(name: "浄水器カートリッジ", cycleDays: 90, daysAgo: [20], memo: "型番 ABC-123"),
        Seed(name: "シャンプー", cycleDays: 60, daysAgo: [], memo: ""),
    ]

    static func insert(into context: ModelContext, today: Date = .now, calendar: Calendar = .current) {
        for (index, seed) in seeds.enumerated() {
            let createdAt = calendar.date(byAdding: .day, value: -100 + index, to: today) ?? today
            let item = Item(name: seed.name, cycleDays: seed.cycleDays, memo: seed.memo, createdAt: createdAt)
            context.insert(item)
            for daysAgo in seed.daysAgo {
                guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) else { continue }
                item.purchases.append(Purchase(purchasedAt: date))
            }
        }
    }
}
