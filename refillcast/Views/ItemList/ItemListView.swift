import SwiftUI

/// 一覧画面（起動時の画面）。
struct ItemListView: View {
    @State private var viewModel: ItemListViewModel
    @Environment(\.scenePhase) private var scenePhase

    init(viewModel: ItemListViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.rows) { row in
                    NavigationLink(value: row.id) {
                        ItemRow(row: row) {
                            withAnimation {
                                viewModel.markPurchased(row.id)
                            }
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button("削除", systemImage: "trash") {
                            viewModel.requestDeletion(row.id)
                        }
                        .tint(.red)
                    }
                }
            }
            .navigationTitle("買い替え予報")
            .navigationDestination(for: UUID.self) { itemID in
                ItemDetailView(viewModel: viewModel.makeDetailViewModel(for: itemID))
            }
            .toolbar {
                if viewModel.canShowSettings {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("設定", systemImage: "gearshape") {
                            viewModel.presentSettings()
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("品目を追加", systemImage: "plus") {
                        viewModel.presentNewItemForm()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if let undo = viewModel.undo {
                    UndoToast(message: undo.message) {
                        withAnimation {
                            viewModel.undoLastPurchase()
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.snappy, value: viewModel.undo?.id)
            .sheet(item: $viewModel.activeSheet) { sheet in
                switch sheet {
                case .itemForm(let formViewModel):
                    ItemFormView(viewModel: formViewModel)
                case .settings(let settingsViewModel):
                    SettingsView(viewModel: settingsViewModel)
                }
            }
            .confirmationDialog(
                Text(viewModel.deleteConfirmationTitle),
                isPresented: $viewModel.isDeleteConfirmationPresented,
                titleVisibility: .visible,
                presenting: viewModel.pendingDeletion
            ) { pending in
                Button("削除", role: .destructive) {
                    withAnimation {
                        viewModel.confirmDeletion(of: pending.id)
                    }
                }
            } message: { _ in
                Text("購入履歴もすべて削除されます。")
            }
        }
        .onChange(of: scenePhase, initial: true) { _, newPhase in
            if newPhase == .active {
                viewModel.sceneDidBecomeActive()
            }
        }
    }
}

#Preview {
    ItemListView(viewModel: AppDependencies.preview().itemListViewModel)
}
