import Foundation
import UIKit

/// 設定アプリの、このアプリの通知設定を開く URL。
///
/// UIKit は URL の定数を参照するためだけに使う（画面は SwiftUI のみで作る）。
enum SystemSettingsLink {
    static var notificationSettingsURL: URL? {
        URL(string: UIApplication.openNotificationSettingsURLString)
    }
}
