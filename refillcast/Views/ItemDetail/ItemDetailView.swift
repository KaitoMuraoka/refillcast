import SwiftUI

/// 品目の詳細画面。
struct ItemDetailView: View {
    @State private var viewModel: ItemDetailViewModel

    init(viewModel: ItemDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.isAvailable {
                content
            } else {
                ContentUnavailableView("品目が見つかりません", systemImage: "questionmark.circle")
            }
        }
        .navigationTitle(viewModel.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if viewModel.isAvailable {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("編集") {
                        viewModel.startEditing()
                    }
                }
            }
        }
        .sheet(item: $viewModel.editForm) { formViewModel in
            ItemFormView(viewModel: formViewModel)
        }
        .sheet(isPresented: $viewModel.isAddingPurchase) {
            AddPurchaseSheet(viewModel: viewModel)
        }
    }

    private var content: some View {
        List {
            Section {
                HStack(spacing: 12) {
                    Image(systemName: viewModel.status.symbolName)
                        .font(.largeTitle)
                        .foregroundStyle(viewModel.status.tint)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.remainingText)
                            .font(.title2.bold())
                            .foregroundStyle(viewModel.status.tint)
                            .monospacedDigit()
                        Text(viewModel.status.label)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
                LabeledContent("次回の買い替え予定日", value: viewModel.dueDateText)
                LabeledContent("最後に買った日", value: viewModel.lastPurchaseText)
                LabeledContent("買い替えの周期", value: viewModel.cycleText)
            }

            if viewModel.hasMemo {
                Section("メモ") {
                    Text(viewModel.memo)
                        .textSelection(.enabled)
                }
            }

            Section {
                ForEach(viewModel.purchaseRows) { row in
                    Text(row.dateText)
                        .monospacedDigit()
                }
                .onDelete { offsets in
                    withAnimation {
                        viewModel.deletePurchases(at: offsets)
                    }
                }
                if !viewModel.hasPurchases {
                    Text("購入履歴はありません")
                        .foregroundStyle(.secondary)
                }
                Button("購入日を追加", systemImage: "plus") {
                    viewModel.startAddingPurchase()
                }
            } header: {
                Text("購入履歴")
            } footer: {
                if viewModel.hasPurchases {
                    Text("左にスワイプすると削除できます。")
                }
            }
        }
    }
}

#Preview {
    let dependencies = AppDependencies.preview()
    NavigationStack {
        if let item = dependencies.store.items.first {
            ItemDetailView(viewModel: ItemDetailViewModel(itemID: item.uuid, store: dependencies.store))
        }
    }
}

#Preview("未購入") {
    let dependencies = AppDependencies.preview()
    NavigationStack {
        if let item = dependencies.store.items.last {
            ItemDetailView(viewModel: ItemDetailViewModel(itemID: item.uuid, store: dependencies.store))
        }
    }
}
