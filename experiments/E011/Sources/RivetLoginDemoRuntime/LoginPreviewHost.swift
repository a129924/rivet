import AppKit
import RivetPresentation
import SwiftUI

/// A separate native window for inspecting product copy without demonstration controls.
@MainActor
public final class LoginPreviewHost: NSObject, NSWindowDelegate {
  let model: LoginDemoModel
  private let configuration: LoginPreviewConfiguration
  private var window: NSWindow?

  public init(configuration: LoginPreviewConfiguration) {
    self.configuration = configuration
    self.model = LoginDemoModel()
    super.init()
    model.show(configuration.scene.phase)
  }

  public func start() {
    guard window == nil else {
      window?.makeKeyAndOrderFront(nil)
      return
    }
    let main = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 780, height: 500),
      styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
      backing: .buffered, defer: false
    )
    main.title = "Rivet"
    main.titleVisibility = .hidden
    main.titlebarAppearsTransparent = true
    main.isMovableByWindowBackground = true
    main.collectionBehavior = [.fullScreenNone]
    main.contentMinSize = NSSize(width: 780, height: 500)
    main.isReleasedWhenClosed = false
    main.delegate = self
    main.appearance =
      switch configuration.appearance {
      case .system: nil
      case .light: NSAppearance(named: .aqua)
      case .dark: NSAppearance(named: .darkAqua)
      }
    main.contentView = NSHostingView(
      rootView: LoginPreviewRoot(model: model, bodyPointSize: configuration.bodyPointSize)
    )
    main.center()
    window = main
    installMenu()
    main.makeKeyAndOrderFront(nil)
  }

  public func windowWillClose(_ notification: Notification) {
    if notification.object as? NSWindow === window { NSApplication.shared.terminate(nil) }
  }

  private func installMenu() {
    let menu = NSMenu()
    let applicationItem = NSMenuItem()
    let applicationMenu = NSMenu()
    applicationMenu.addItem(
      withTitle: "Quit Rivet", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"
    )
    applicationItem.submenu = applicationMenu
    menu.addItem(applicationItem)
    let editItem = NSMenuItem()
    editItem.title = "Edit"
    let editMenu = NSMenu(title: "Edit")
    for (title, action, key) in [
      ("Cut", "cut:", "x"), ("Copy", "copy:", "c"), ("Paste", "paste:", "v"),
      ("Select All", "selectAll:", "a"),
    ] {
      editMenu.addItem(withTitle: title, action: Selector(action), keyEquivalent: key)
    }
    editItem.submenu = editMenu
    menu.addItem(editItem)
    NSApplication.shared.mainMenu = menu
    NSApplication.shared.windowsMenu = nil
  }
}

private struct LoginPreviewRoot: View {
  let model: LoginDemoModel
  let bodyPointSize: CGFloat

  var body: some View {
    RivetLoginView(
      phase: model.phase,
      footer: LoginPreviewConfiguration.footer,
      bodyPointSize: bodyPointSize,
      content: .standard,
      onIntent: model.handle
    )
    .id(model.formIdentity)
    .frame(minWidth: 780, minHeight: 500)
    .ignoresSafeArea()
  }
}
