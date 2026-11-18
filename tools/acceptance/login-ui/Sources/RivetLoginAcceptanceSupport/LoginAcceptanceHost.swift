import AppKit
import RivetPresentation
import SwiftUI

/// The only cross-target entry point; all acceptance models stay tool-local.
@MainActor
public func runLoginAcceptance(arguments: [String]) {
  let configuration: LoginAcceptanceConfiguration
  do {
    configuration = try LoginAcceptanceConfiguration(arguments: arguments)
  } catch {
    FileHandle.standardError.write(Data((LoginAcceptanceConfiguration.usage + "\n").utf8))
    exit(2)
  }
  let application = NSApplication.shared
  let delegate = LoginAcceptanceApplicationDelegate()
  application.delegate = delegate
  application.setActivationPolicy(.regular)
  let host = LoginAcceptanceHost(configuration: configuration)
  host.start()
  application.activate(ignoringOtherApps: true)
  withExtendedLifetime((delegate, host)) { application.run() }
}

@MainActor
private final class LoginAcceptanceApplicationDelegate: NSObject, NSApplicationDelegate {
  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

@MainActor
final class LoginAcceptanceHost: NSObject, NSWindowDelegate, NSMenuDelegate {
  private typealias Scene = LoginAcceptanceConfiguration.Scene
  private let configuration: LoginAcceptanceConfiguration
  private let parent: LoginAcceptanceParent
  private var window: NSWindow?
  private var phaseItems: [NSMenuItem] = []
  private var sizeItems: [NSMenuItem] = []
  private var contentItems: [NSMenuItem] = []
  private let creationItem = NSMenuItem()
  private let receiptItem = NSMenuItem()

  init(configuration: LoginAcceptanceConfiguration) {
    self.configuration = configuration
    self.parent = LoginAcceptanceParent(configuration: configuration)
    super.init()
  }

  func start() {
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
    main.contentView = NSHostingView(rootView: LoginAcceptanceRoot(parent: parent))
    main.center()
    window = main
    installMenu()
    main.makeKeyAndOrderFront(nil)
  }

  func windowWillClose(_ notification: Notification) {
    if notification.object as? NSWindow === window { NSApplication.shared.terminate(nil) }
  }

  private func installMenu() {
    let menuBar = NSMenu()
    let applicationItem = NSMenuItem()
    let applicationMenu = NSMenu()
    applicationMenu.addItem(
      withTitle: "Quit Rivet Login Acceptance", action: #selector(NSApplication.terminate(_:)),
      keyEquivalent: "q")
    applicationItem.submenu = applicationMenu
    menuBar.addItem(applicationItem)
    let editItem = NSMenuItem()
    editItem.title = "Edit"
    let editMenu = NSMenu(title: "Edit")
    for (title, action, key) in [
      ("Cut", "cut:", "x"), ("Copy", "copy:", "c"), ("Paste", "paste:", "v"),
      ("Select All", "selectAll:", "a"),
    ] { editMenu.addItem(withTitle: title, action: Selector(action), keyEquivalent: key) }
    editItem.submenu = editMenu
    menuBar.addItem(editItem)

    let acceptanceItem = NSMenuItem()
    acceptanceItem.title = "Acceptance"
    let acceptanceMenu = NSMenu(title: "Acceptance")
    acceptanceMenu.delegate = self
    let phases = NSMenu(title: "Phase")
    phases.delegate = self
    for scene in Scene.allCases {
      let item = controlItem(
        LoginAcceptanceFixtures.title(for: scene), #selector(selectPhase(_:)), scene.rawValue)
      phaseItems.append(item)
      phases.addItem(item)
    }
    addSubmenu(phases, to: acceptanceMenu)
    let sizes = NSMenu(title: "Text size")
    sizes.delegate = self
    for size in [13, 17, 21] {
      let item = controlItem("\(size) pt", #selector(selectSize(_:)), String(size))
      sizeItems.append(item)
      sizes.addItem(item)
    }
    addSubmenu(sizes, to: acceptanceMenu)
    let copy = NSMenu(title: "Content")
    copy.delegate = self
    for selection in LoginAcceptanceParent.ContentSelection.allCases {
      let item = controlItem(
        selection.rawValue.capitalized, #selector(selectContent(_:)), selection.rawValue)
      contentItems.append(item)
      copy.addItem(item)
    }
    addSubmenu(copy, to: acceptanceMenu)
    creationItem.title = "Enable token creation"
    creationItem.target = self
    creationItem.action = #selector(toggleCreation)
    acceptanceMenu.addItem(creationItem)
    acceptanceMenu.addItem(controlItem("Reset", #selector(reset), nil))
    acceptanceMenu.addItem(.separator())
    receiptItem.isEnabled = false
    acceptanceMenu.addItem(receiptItem)
    acceptanceItem.submenu = acceptanceMenu
    menuBar.addItem(acceptanceItem)
    NSApplication.shared.mainMenu = menuBar
    NSApplication.shared.windowsMenu = nil
  }

  private func controlItem(_ title: String, _ action: Selector, _ value: String?) -> NSMenuItem {
    let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
    item.target = self
    item.representedObject = value
    return item
  }

  private func addSubmenu(_ submenu: NSMenu, to menu: NSMenu) {
    let item = NSMenuItem()
    item.title = submenu.title
    item.submenu = submenu
    menu.addItem(item)
  }

  func menuNeedsUpdate(_ menu: NSMenu) {
    for item in phaseItems {
      guard let raw = item.representedObject as? String else { continue }
      guard let scene = Scene(rawValue: raw) else { continue }
      item.state = parent.phase == LoginAcceptanceFixtures.phase(for: scene) ? .on : .off
    }
    for item in sizeItems {
      if let raw = item.representedObject as? String, let value = Double(raw) {
        item.state = parent.bodyPointSize == CGFloat(value) ? .on : .off
      }
    }
    for item in contentItems {
      item.state =
        item.representedObject as? String == parent.contentSelection.rawValue ? .on : .off
    }
    creationItem.state = parent.canCreateToken ? .on : .off
    receiptItem.title =
      "Last event: \(parent.lastEventKind?.rawValue ?? "None") · Count: \(parent.eventCount)"
  }

  @objc private func selectPhase(_ sender: NSMenuItem) {
    guard let raw = sender.representedObject as? String,
      let scene = Scene(rawValue: raw)
    else { return }
    parent.selectScene(scene)
  }

  @objc private func selectSize(_ sender: NSMenuItem) {
    guard let raw = sender.representedObject as? String, let value = Double(raw) else { return }
    parent.setBodyPointSize(CGFloat(value))
  }

  @objc private func selectContent(_ sender: NSMenuItem) {
    guard let raw = sender.representedObject as? String,
      let selection = LoginAcceptanceParent.ContentSelection(rawValue: raw)
    else { return }
    parent.selectContent(selection)
  }

  @objc private func toggleCreation() { parent.setCanCreateToken(!parent.canCreateToken) }
  @objc private func reset() { parent.reset() }
}

private struct LoginAcceptanceRoot: View {
  let parent: LoginAcceptanceParent

  var body: some View {
    RivetLoginView(
      phase: parent.phase, footer: LoginAcceptanceFixtures.footer,
      bodyPointSize: parent.bodyPointSize,
      content: parent.content, canCreateToken: parent.canCreateToken, onIntent: parent.handle
    )
    .id(parent.formGeneration)
    .frame(minWidth: 780, minHeight: 500)
    .ignoresSafeArea()
  }
}
