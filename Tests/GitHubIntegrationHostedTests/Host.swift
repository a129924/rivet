import AppKit

// 測試容器不組裝依賴；Xcode 將 test bundle 載入此程序。
@main
struct GitHubIntegrationTestHost {
  static func main() {
    let application = NSApplication.shared
    application.setActivationPolicy(.prohibited)
    application.run()
  }
}
