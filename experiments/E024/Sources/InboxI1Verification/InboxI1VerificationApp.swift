import SwiftUI

enum InboxCommand: Equatable {
  case scenario(InboxScenario)
  case focusVerification
  case injectRemovedB
  case appearance(ColorScheme?)
  case togglePicker
  case toggleLongTitle
  case width(CGFloat)
}

@main
struct InboxI1VerificationApp: App {
  @State private var command: InboxCommand?

  var body: some Scene {
    Window("PR Inbox · I1 驗證", id: "inbox") {
      InboxWindow(command: $command)
    }
    .defaultSize(width: 940, height: 560)
    .windowResizability(.contentMinSize)
    .commands {
      CommandMenu("驗證情境") {
        ForEach(InboxScenario.allCases, id: \.self) { scenario in
          Button(scenario.label) { command = .scenario(scenario) }
        }
        Divider()
        Button("聚焦 Open 事件紀錄") { command = .focusVerification }
        Button("注入已移除的 B") { command = .injectRemovedB }
        Button("切換驗收用 Picker") { command = .togglePicker }
        Button("切換長標題") { command = .toggleLongTitle }
        Menu("內容寬度") {
          Button("420 pt") { command = .width(420) }
          Button("940 pt") { command = .width(940) }
        }
        Divider()
        Menu("外觀") {
          Button("跟隨系統") { command = .appearance(nil) }
          Button("明亮") { command = .appearance(.light) }
          Button("深色") { command = .appearance(.dark) }
        }
      }
    }
  }
}
