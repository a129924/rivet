import AppKit
import Foundation
import SystemConfiguration

@main enum AppMain {
  static func main() {
    let args = Array(CommandLine.arguments.dropFirst())
    guard args.count == 4, args[0] == "--root", args[2] == "--ticket" else { exit(2) }
    do {
      let context = try LiveGate.context(URL(fileURLWithPath: args[1]), args[3])
      let app = NSApplication.shared; let delegate = ProbeDelegate(context)
      app.delegate = delegate; app.setActivationPolicy(.regular); app.run(); withExtendedLifetime(delegate) {}
    } catch { exit(2) }
  }
}
@MainActor final class ProbeDelegate: NSObject, NSApplicationDelegate {
  let context: LiveContext
  var window: NSWindow?
  init(_ context: LiveContext) { self.context = context }
  func applicationDidFinishLaunching(_ notification: Notification) {
    let label = NSTextField(labelWithString: "E010：分段 DPK 假憑證觀察")
    label.frame = NSRect(x: 20, y: 25, width: 500, height: 40)
    let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 540, height: 90), styleMask: [.titled], backing: .buffered, defer: false)
    window.title = "E010 受限實驗"; window.contentView?.addSubview(label); window.center(); window.makeKeyAndOrderFront(nil)
    self.window = window; NSApp.activate(ignoringOtherApps: true)
    DispatchQueue.main.async { self.performOnce() }
  }
  func performOnce() {
    var store: LiveStore?
    var receipt: [String: Any] = ["namespace": context.namespace, "ticket": context.ticketID,
      "synthetic": false, "startedUTC": ISO8601DateFormatter().string(from: Date()),
      "launch": "started", "guard": "rejected", "callAttempted": false, "OSStatus": NSNull(), "promptCount": NSNull()]
    if let binary = Bundle.main.executableURL, let bytes = try? Data(contentsOf: binary) { receipt["executableSHA256"] = LiveGate.hash(bytes) }
    receipt["proofSHA256"] = context.ticket["proofSHA256"]
    do {
      var uid: uid_t = 0; var gid: gid_t = 0
      let console = SCDynamicStoreCopyConsoleUser(nil, &uid, &gid) as String?
      let permit = try LiveGate.authorize(context, guiUser: uid == getuid() && uid != 0 && console != nil && console != "loginwindow")
      try LiveGate.write(permit.root, "process/\(permit.ticketID).json", ["namespace": permit.namespace, "ticket": permit.ticketID, "pid": getpid()])
      let backend = LiveStore(permit); store = backend; receipt["guard"] = "passed"
      let result = try ProbeCore(store: backend).perform(permit.action)
      receipt["fields"] = result.fields; if let absent = result.absent { receipt["absent"] = absent }
      receipt["completed"] = true; receipt["classification"] = "completed"
    } catch {
      receipt["completed"] = false
      receipt["classification"] = (error as? ProbeError)?.classification ?? "guardRejected"
    }
    receipt["callAttempted"] = (store?.calls ?? 0) > 0
    receipt["OSStatus"] = store?.lastStatus.map { $0 as Any } ?? NSNull()
    receipt["endedUTC"] = ISO8601DateFormatter().string(from: Date())
    do { try LiveGate.write(context.root, "app-receipts/\(context.ticketID).json", receipt) }
    catch { NSApp.terminate(nil); return }
    NSApp.terminate(nil)
  }
}
