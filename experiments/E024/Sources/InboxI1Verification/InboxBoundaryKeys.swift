import AppKit
import Carbon.HIToolbox
import SwiftUI

// Support the standard Home and End key codes even when SwiftUI represents them with hardware flags.
struct InboxBoundaryKeys: NSViewRepresentable {
  enum Edge {
    case first, last
  }

  var select: (Edge) -> Bool

  func makeNSView(context: Context) -> MonitorView {
    MonitorView()
  }

  func updateNSView(_ view: MonitorView, context: Context) {
    view.select = select
  }

  static func dismantleNSView(_ view: MonitorView, coordinator: ()) {
    view.stop()
  }

  final class MonitorView: NSView {
    var select: (Edge) -> Bool = { _ in false }
    private var monitor: Any?

    override func viewDidMoveToWindow() {
      super.viewDidMoveToWindow()
      stop()
      guard window != nil else { return }
      monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
        guard let self, let window, event.window === window,
          event.modifierFlags.isDisjoint(with: [.shift, .control, .option, .command])
        else { return event }

        switch event.keyCode {
        case UInt16(kVK_Home): return select(.first) ? nil : event
        case UInt16(kVK_End): return select(.last) ? nil : event
        default: return event
        }
      }
    }

    func stop() {
      guard let monitor else { return }
      NSEvent.removeMonitor(monitor)
      self.monitor = nil
    }
  }
}
