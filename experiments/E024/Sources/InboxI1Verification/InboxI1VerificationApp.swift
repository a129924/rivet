import SwiftUI

enum InboxCommand: Equatable {
  case scenario(InboxScenario)
  case focusVerification
  case injectRemovedB
  case appearance(ColorScheme?)
}

@main
struct InboxI1VerificationApp: App {
  @State private var command: InboxCommand?

  var body: some Scene {
    Window("PR Inbox · I1 驗證", id: "inbox") {
      InboxWindow(command: $command)
    }
    .defaultSize(width: 940, height: 560)
    .commands {
      CommandMenu("驗證情境") {
        ForEach(InboxScenario.allCases, id: \.self) { scenario in
          Button(scenario.label) { command = .scenario(scenario) }
        }
        Divider()
        Button("聚焦 Open 事件紀錄") { command = .focusVerification }
        Button("注入已移除的 B") { command = .injectRemovedB }
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
