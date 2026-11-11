import Foundation
import SwiftData

/// SwiftData の ModelContainer を作る。
enum ModelContainerFactory {
    /// - Parameter inMemory: true のときは端末に保存しない（プレビューとテスト用）。
    static func make(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema(versionedSchema: RefillcastSchemaV1.self)
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory
        )
        return try ModelContainer(
            for: schema,
            migrationPlan: RefillcastMigrationPlan.self,
            configurations: configuration
        )
    }
}
