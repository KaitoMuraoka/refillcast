import Foundation
import SwiftData
import SwiftUI

/// プレビュー用のインメモリ ModelContainer とサンプルデータ。
struct SampleDataPreviewModifier: PreviewModifier {
    static func makeSharedContext() async throws -> ModelContainer {
        let container = try ModelContainerFactory.make(inMemory: true)
        PreviewSampleData.insert(into: container.mainContext)
        return container
    }

    func body(content: Content, context: ModelContainer) -> some View {
        content.modelContainer(context)
    }
}

extension PreviewTrait where T == Preview.ViewTraits {
    /// サンプルデータ入りの ModelContainer を注入する。
    static var sampleData: Self { .modifier(SampleDataPreviewModifier()) }
}

enum PreviewSampleData {
    /// (名前, 周期, 何日前に買ったか。nil は未購入, メモ)
    private static let seeds: [(String, Int, [Int]?, String)] = [
        ("歯ブラシ", 30, [33, 63], "やわらかめ"),
        ("洗濯用洗剤", 45, [40, 88], "詰め替え用"),
        ("コンタクトレンズ", 14, [9], ""),
        ("浄水器カートリッジ", 90, [20], "型番 ABC-123"),
        ("シャンプー", 60, nil, ""),
    ]

    static func insert(into context: ModelContext, today: Date = .now, calendar: Calendar = .current) {
        for (name, cycleDays, daysAgoList, memo) in seeds {
            let item = Item(name: name, cycleDays: cycleDays, memo: memo)
            context.insert(item)
            for daysAgo in daysAgoList ?? [] {
                guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) else { continue }
                item.purchases.append(Purchase(purchasedAt: date))
            }
        }
    }
}
