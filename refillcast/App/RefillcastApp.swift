import SwiftUI

@main
struct RefillcastApp: App {
    @State private var launchState = AppLaunchState.make()

    var body: some Scene {
        WindowGroup {
            switch launchState {
            case .ready(let dependencies):
                ItemListView(viewModel: dependencies.itemListViewModel)
            case .failed:
                StorageErrorView()
            }
        }
    }
}
