import Foundation
import SwiftData

/// 起動時にデータの保存先を用意できたかどうか。
enum AppLaunchState {
    case ready(ModelContainer)
    case failed

    static func make() -> AppLaunchState {
        do {
            return .ready(try ModelContainerFactory.make())
        } catch {
            return .failed
        }
    }
}
