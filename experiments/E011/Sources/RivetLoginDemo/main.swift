import AppKit
import RivetLoginDemoRuntime

@MainActor
private final class LoginDemoApplicationDelegate: NSObject, NSApplicationDelegate {
  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

@MainActor
func main() {
  var arguments = Array(CommandLine.arguments.dropFirst())
  let previewBundle = Bundle.main.bundleIdentifier == LoginPreviewConfiguration.bundleIdentifier
  if previewBundle && !arguments.contains("--preview") {
    arguments.insert("--preview", at: 0)
  }
  let preview: LoginPreviewConfiguration?
  do {
    preview =
      arguments.contains("--preview") ? try LoginPreviewConfiguration(arguments: arguments) : nil
  } catch {
    FileHandle.standardError.write(Data((LoginPreviewConfiguration.usage + "\n").utf8))
    exit(2)
  }
  let application = NSApplication.shared
  let delegate = LoginDemoApplicationDelegate()
  application.delegate = delegate
  application.setActivationPolicy(.regular)
  let host: NSObject
  if let preview {
    let previewHost = LoginPreviewHost(configuration: preview)
    previewHost.start()
    host = previewHost
  } else {
    let demoHost = LoginDemoHost()
    demoHost.start()
    host = demoHost
  }
  application.activate(ignoringOtherApps: true)
  withExtendedLifetime((delegate, host)) { application.run() }
}

main()
