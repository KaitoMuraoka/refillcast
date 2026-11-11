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
                    ItemRow(row: row) {
                        withAnimation {
                            viewModel.markPurchased(row.id)
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
            .toolbar {
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
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                viewModel.sceneDidBecomeActive()
            }
        }
    }
}

#Preview {
    ItemListView(viewModel: AppDependencies.preview().itemListViewModel)
}
