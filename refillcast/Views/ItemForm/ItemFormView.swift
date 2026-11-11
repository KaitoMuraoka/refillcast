import SwiftUI

/// 品目の登録・編集画面。
struct ItemFormView: View {
    @Bindable var viewModel: ItemFormViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                nameSection
                cycleSection
                if viewModel.showsInitialPurchase {
                    initialPurchaseSection
                }
                memoSection
            }
            .scrollDismissesKeyboard(.interactively)
            .alert("エラー", isPresented: $viewModel.isErrorPresented) {
                Button("OK") {}
            } message: {
                Text(viewModel.errorMessage)
            }
            .navigationTitle(viewModel.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル", systemImage: "xmark", role: .cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存", systemImage: "checkmark", role: .confirm) {
                        if viewModel.save() {
                            dismiss()
                        }
                    }
                    .disabled(!viewModel.canSave)
                }
            }
        }
    }

    private var nameSection: some View {
        Section {
            TextField("例：歯ブラシ", text: $viewModel.name)
                .submitLabel(.done)
        } header: {
            Text("名前")
        } footer: {
            HStack(alignment: .firstTextBaseline) {
                if let message = viewModel.nameErrorMessage {
                    Text(message)
                        .foregroundStyle(.red)
                }
                Spacer()
                Text(viewModel.nameCountText)
                    .monospacedDigit()
                    .foregroundStyle(viewModel.isNameTooLong ? .red : .secondary)
            }
        }
    }

    private var cycleSection: some View {
        Section {
            HStack {
                TextField("日数", text: $viewModel.cycleDaysText)
                    .keyboardType(.numberPad)
                Text("日ごと")
                    .foregroundStyle(.secondary)
            }
            Menu {
                ForEach(viewModel.cyclePresets) { preset in
                    Button(viewModel.presetLabel(preset)) {
                        viewModel.selectPreset(preset)
                    }
                }
            } label: {
                Label("候補から選ぶ", systemImage: "list.bullet")
            }
        } header: {
            Text("買い替えの周期")
        } footer: {
            if let message = viewModel.cycleErrorMessage {
                Text(message)
                    .foregroundStyle(.red)
            }
        }
    }

    private var initialPurchaseSection: some View {
        Section {
            Toggle("購入日を記録する", isOn: $viewModel.recordsInitialPurchase)
            if viewModel.recordsInitialPurchase {
                DatePicker(
                    "最後に買った日",
                    selection: $viewModel.initialPurchaseDate,
                    in: ...viewModel.latestSelectablePurchaseDate,
                    displayedComponents: .date
                )
            }
        } header: {
            Text("最後に買った日")
        } footer: {
            Text("記録しない場合は「未購入」として登録します。")
        }
    }

    private var memoSection: some View {
        Section("メモ") {
            TextField("任意", text: $viewModel.memo, axis: .vertical)
                .lineLimit(3...6)
        }
    }
}

#Preview("新規登録") {
    let dependencies = AppDependencies.preview()
    ItemFormView(viewModel: ItemFormViewModel(store: dependencies.store, mode: .create))
}

#Preview("編集") {
    let dependencies = AppDependencies.preview()
    if let item = dependencies.store.items.first {
        ItemFormView(viewModel: ItemFormViewModel(store: dependencies.store, mode: .edit(item)))
    }
}
