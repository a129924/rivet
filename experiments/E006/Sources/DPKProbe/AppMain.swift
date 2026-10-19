import AppKit
import Foundation
import SystemConfiguration

@main enum AppMain {
  static func main() {
    let app = NSApplication.shared
    let delegate = ProbeDelegate()
    app.delegate = delegate
    app.setActivationPolicy(.regular)
    app.run()
    withExtendedLifetime(delegate) {}
  }
}
@MainActor final class ProbeDelegate: NSObject, NSApplicationDelegate {
  private var window: NSWindow?
  func applicationDidFinishLaunching(_ notification: Notification) {
    let view = NSTextField(labelWithString: "DPK 隔離假憑證實驗：驗證前提中")
    view.frame = NSRect(x: 20, y: 30, width: 500, height: 40)
    let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 540, height: 100),
      styleMask: [.titled], backing: .buffered, defer: false)
    window.title = "E006 可行性實驗"; window.contentView?.addSubview(view)
    window.center(); window.makeKeyAndOrderFront(nil); self.window = window
    NSApp.activate(ignoringOtherApps: true)
    DispatchQueue.main.async { self.performOnce(label: view) }
  }
  private func performOnce(label: NSTextField) {
    var authorization: LiveAuthorization?
    var receipt: [String: Any] = [:]
    do {
      let args = Array(CommandLine.arguments.dropFirst())
      guard args.count == 8, args[0] == "--scratch", args[2] == "--namespace",
        args[4] == "--phase", args[6] == "--operation", let phase = Int(args[5]),
        let operation = Operation(rawValue: args[7]), let executable = Bundle.main.executableURL
      else { throw ProbeError.guardRejected }
      var uid: uid_t = 0; var gid: gid_t = 0
      let console = SCDynamicStoreCopyConsoleUser(nil, &uid, &gid) as String?
      let permitted = uid == getuid() && uid != 0 && console != nil && console != "loginwindow"
      let permit = try LiveGate.authorize(root: URL(fileURLWithPath: args[1]), namespace: args[3],
        phase: phase, operation: operation, executable: executable, bundle: .main, guiUser: permitted)
      authorization = permit
      let processData = try JSONSerialization.data(withJSONObject: ["pid": getpid(), "phase": phase, "namespace": args[3]])
      let processPath = try LiveGate.safe(permit.root, "control/process-\(phase).json")
      let processFD = processPath.path.withCString { open($0, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, 0o600) }
      guard processFD >= 0 else { throw ProbeError.guardRejected }
      let processFile = FileHandle(fileDescriptor: processFD, closeOnDealloc: true)
      try processFile.write(contentsOf: processData); try processFile.close()
      receipt = ["namespace":args[3], "phase":phase, "operation":operation.rawValue,
        "observationMode":"human-only", "synthetic":false, "startedUTC":permit.started,
        "executableSHA256":permit.binaryHash, "proofSHA256":permit.proofHash, "promptCount":NSNull()]
      let result = try ProbeCore(store: LiveStore(authorization: permit)).perform(operation)
      receipt["fields"] = result.fields
      if let absent = result.absent { receipt["absent"] = absent }
      receipt["completed"] = true
      label.stringValue = "本段完成；等待 Human 觀察回報"
    } catch {
      let failure = error as? ProbeError
      receipt["completed"] = false
      receipt["error"] = failure?.classification ?? "guardRejected"
      if case .security(_, let status)? = failure { receipt["status"] = status }
      label.stringValue = "本段停止；未推論系統提示"
    }
    receipt["endedUTC"] = ISO8601DateFormatter().string(from: Date())
    if let permit = authorization {
      do {
        let url = try LiveGate.safe(permit.root, "receipts/phase-\(permit.phaseNumber).machine.json")
        let data = try JSONSerialization.data(withJSONObject: receipt, options: [.sortedKeys, .prettyPrinted])
        let fd = url.path.withCString { open($0, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, 0o600) }
        guard fd >= 0 else { throw ProbeError.guardRejected }
        let handle = FileHandle(fileDescriptor: fd, closeOnDealloc: true)
        try handle.write(contentsOf: data)
        try handle.close()
      } catch { NSApp.terminate(nil); return }
    }
    // One operation and receipt per App process; coordinator waits for this PID to exit.
    NSApp.terminate(nil)
  }
}
