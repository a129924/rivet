import AppKit
import RivetLoginDemoRuntime

@MainActor
private final class LoginDemoApplicationDelegate: NSObject, NSApplicationDelegate {
  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

@MainActor
func main() {
  let application = NSApplication.shared
  let delegate = LoginDemoApplicationDelegate()
  application.delegate = delegate
  application.setActivationPolicy(.regular)
  let host = LoginDemoHost()
  host.start()
  application.activate(ignoringOtherApps: true)
  withExtendedLifetime((delegate, host)) { application.run() }
}

main()
