import SwiftUI

/// 過去の日付で購入履歴を追加するシート。
struct AddPurchaseSheet: View {
    @Bindable var viewModel: ItemDetailViewModel

    var body: some View {
        NavigationStack {
            Form {
                DatePicker(
                    "購入日",
                    selection: $viewModel.newPurchaseDate,
                    in: ...viewModel.latestSelectablePurchaseDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
            }
            .navigationTitle("購入日を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル", systemImage: "xmark", role: .cancel) {
                        viewModel.cancelAddingPurchase()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("追加", systemImage: "checkmark", role: .confirm) {
                        viewModel.addPurchase()
                    }
                }
            }
        }
        .presentationDetents([.large])
    }
}

#Preview {
    let dependencies = AppDependencies.preview()
    if let item = dependencies.store.items.first {
        AddPurchaseSheet(viewModel: ItemDetailViewModel(itemID: item.uuid, store: dependencies.store))
    }
}
