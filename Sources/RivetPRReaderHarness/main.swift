import AppKit
import RivetPRReaderHarnessRuntime

@MainActor
private final class HarnessApplicationDelegate: NSObject, NSApplicationDelegate {
  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

@MainActor
func main() {
  let application = NSApplication.shared
  let delegate = HarnessApplicationDelegate()
  application.delegate = delegate
  application.setActivationPolicy(.regular)
  let harness = ReaderHarness()
  harness.start()
  application.activate(ignoringOtherApps: true)
  application.run()
}

main()
