import SwiftData
import SwiftUI

@main
struct RefillcastApp: App {
    private let launchState = AppLaunchState.make()

    var body: some Scene {
        WindowGroup {
            switch launchState {
            case .ready(let container):
                RootView()
                    .modelContainer(container)
            case .failed:
                StorageErrorView()
            }
        }
    }
}
