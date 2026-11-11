import Foundation
import SwiftData

/// アプリで使う最新のスキーマ。
///
/// モデルに項目を足すときは `RefillcastSchemaV2` を追加し、
/// `RefillcastMigrationPlan` に移行ステージを登録してから、ここの typealias を差し替える。
typealias Item = RefillcastSchemaV1.Item
typealias Purchase = RefillcastSchemaV1.Purchase

enum RefillcastSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Item.self, Purchase.self]
    }
}

enum RefillcastMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [RefillcastSchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}
