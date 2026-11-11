import Foundation

/// 起動時にデータの保存先を用意できたかどうか。
enum AppLaunchState {
    case ready(AppDependencies)
    case failed

    static func make() -> AppLaunchState {
        do {
            return .ready(try AppDependencies.live())
        } catch {
            return .failed
        }
    }
}
