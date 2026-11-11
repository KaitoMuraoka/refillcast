import SwiftUI

/// 設定画面。
struct SettingsView: View {
    @Bindable var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            Form {
                if viewModel.showsPermissionDeniedGuidance {
                    permissionDeniedSection
                }
                notificationSection
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる", systemImage: "xmark", role: .close) {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await viewModel.refreshAuthorization()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            Task {
                await viewModel.refreshAuthorization()
            }
        }
    }

    private var permissionDeniedSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 6) {
                Label("通知が許可されていません", systemImage: "bell.slash.fill")
                    .font(.headline)
                    .foregroundStyle(.orange)
                Text("買い替え時期のお知らせを受け取るには、設定アプリで Refillcast の通知を許可してください。通知が届かなくても、アプリはこれまでどおり使えます。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
            if let url = viewModel.notificationSettingsURL {
                Button("設定アプリを開く", systemImage: "arrow.up.forward.app") {
                    openURL(url)
                }
            }
        }
    }

    private var notificationSection: some View {
        Section {
            Toggle("買い替え時期を通知する", isOn: $viewModel.isNotificationEnabled)
            if viewModel.isNotificationEnabled {
                DatePicker(
                    "通知する時刻",
                    selection: $viewModel.reminderTime,
                    displayedComponents: .hourAndMinute
                )
                Picker("通知する日", selection: $viewModel.leadTime) {
                    ForEach(viewModel.leadTimeOptions, id: \.self) { option in
                        Text(viewModel.label(for: option))
                            .tag(option)
                    }
                }
            }
        } header: {
            Text("通知")
        } footer: {
            if viewModel.showsPermissionPendingNote {
                Text("最初の品目を登録したときに、通知の許可を求めます。")
            } else {
                Text("買い替え予定日（または指定した日数前）の指定した時刻にお知らせします。")
            }
        }
    }
}

#Preview("許可済み") {
    SettingsView(viewModel: AppDependencies.preview().settingsViewModel)
}

#Preview("許可されていない") {
    SettingsView(viewModel: AppDependencies.preview(notificationStatus: .denied).settingsViewModel)
}
