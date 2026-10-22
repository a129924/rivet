import AppKit
import RivetPresentation
import SwiftUI

@MainActor
public final class LoginDemoHost: NSObject, NSWindowDelegate {
  private let model = LoginDemoModel()
  private var window: NSWindow?
  private var controls: NSWindow?

  public override init() { super.init() }

  public func start() {
    let main = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 780, height: 500),
      styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
      backing: .buffered, defer: false
    )
    main.title = "Rivet Login Demo"
    main.titleVisibility = .hidden
    main.titlebarAppearsTransparent = true
    main.isMovableByWindowBackground = true
    main.collectionBehavior = [.fullScreenNone]
    main.contentMinSize = NSSize(width: 780, height: 500)
    main.isReleasedWhenClosed = false
    main.delegate = self
    main.contentView = NSHostingView(rootView: LoginDemoRoot(model: model))
    main.center()
    window = main

    let panel = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 310, height: 390),
      styleMask: [.titled, .closable], backing: .buffered, defer: false
    )
    panel.title = "Rivet Demo Controls"
    panel.isReleasedWhenClosed = false
    panel.contentView = NSHostingView(
      rootView: LoginDemoControls(model: model) { [weak self] appearance in
        self?.setAppearance(appearance)
      }
    )
    let visible = main.screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
    panel.setFrameOrigin(
      NSPoint(x: min(main.frame.maxX + 16, visible.maxX - 320), y: main.frame.minY))
    controls = panel
    panel.orderFront(nil)
    main.makeKeyAndOrderFront(nil)
    installMenu()
  }

  public func windowWillClose(_ notification: Notification) {
    if notification.object as? NSWindow === window { NSApplication.shared.terminate(nil) }
  }

  private func setAppearance(_ appearance: DemoAppearance) {
    let native: NSAppearance? =
      switch appearance {
      case .system: nil
      case .light: NSAppearance(named: .aqua)
      case .dark: NSAppearance(named: .darkAqua)
      }
    window?.appearance = native
    controls?.appearance = native
  }

  private func installMenu() {
    let menu = NSMenu()
    let applicationItem = NSMenuItem()
    let appMenu = NSMenu()
    appMenu.addItem(
      withTitle: "Quit Rivet Login Demo", action: #selector(NSApplication.terminate(_:)),
      keyEquivalent: "q")
    applicationItem.submenu = appMenu
    menu.addItem(applicationItem)
    let edit = NSMenuItem()
    edit.title = "Edit"
    let editMenu = NSMenu(title: "Edit")
    for (title, action, key) in [
      ("Cut", "cut:", "x"), ("Copy", "copy:", "c"), ("Paste", "paste:", "v"),
      ("Select All", "selectAll:", "a"),
    ] {
      editMenu.addItem(withTitle: title, action: Selector(action), keyEquivalent: key)
    }
    edit.submenu = editMenu
    menu.addItem(edit)
    let windowItem = NSMenuItem()
    windowItem.title = "Window"
    let windowMenu = NSMenu(title: "Window")
    let showControls = NSMenuItem(
      title: "Demo Controls", action: #selector(showControlWindow), keyEquivalent: "0")
    showControls.target = self
    windowMenu.addItem(showControls)
    windowItem.submenu = windowMenu
    menu.addItem(windowItem)
    NSApplication.shared.mainMenu = menu
    NSApplication.shared.windowsMenu = windowMenu
  }

  @objc private func showControlWindow() { controls?.makeKeyAndOrderFront(nil) }
}

private enum DemoAppearance: String, CaseIterable {
  case system = "System"
  case light = "Light"
  case dark = "Dark"
}

private struct LoginDemoRoot: View {
  let model: LoginDemoModel
  var body: some View {
    RivetLoginView(
      phase: model.phase,
      footer: "UI demonstration · No GitHub requests or credential storage.",
      onIntent: model.handle
    )
    .id(model.formIdentity)
    .frame(minWidth: 780, minHeight: 500)
    .ignoresSafeArea()
  }
}

private enum DemoPhase: String, CaseIterable {
  case welcome = "Welcome"
  case token = "PAT input"
  case waiting = "Waiting for browser"
  case account = "Verifying account"
  case checkingToken = "Verifying token"
  case failure = "Failure"
  case connected = "Connected"

  init(_ phase: RivetLoginPhase) {
    switch phase {
    case .welcome: self = .welcome
    case .tokenEntry: self = .token
    case .waitingForBrowser: self = .waiting
    case .verifyingAccount: self = .account
    case .verifyingToken: self = .checkingToken
    case .failure: self = .failure
    case .connected: self = .connected
    }
  }

  @MainActor func presentation(origin: RivetLoginFailure.Origin) -> RivetLoginPhase {
    switch self {
    case .welcome: .welcome
    case .token: .tokenEntry
    case .waiting: .waitingForBrowser
    case .account: .verifyingAccount
    case .checkingToken: .verifyingToken
    case .failure: .failure(.init(message: LoginDemoModel.failureMessage, origin: origin))
    case .connected: .connected
    }
  }
}

private struct LoginDemoControls: View {
  @Bindable var model: LoginDemoModel
  let onAppearance: (DemoAppearance) -> Void
  @State private var appearance: DemoAppearance = .system
  @State private var failureOrigin: RivetLoginFailure.Origin = .browser

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("UI demonstration").font(.headline)
      Text("Example input only. No browser, API, Keychain or saved credentials.")
        .font(.callout).foregroundStyle(.secondary)
      Picker("Appearance", selection: $appearance) {
        ForEach(DemoAppearance.allCases, id: \.self) { Text($0.rawValue).tag($0) }
      }
      .pickerStyle(.segmented).onChange(of: appearance) { _, value in onAppearance(value) }
      Picker(
        "Display state",
        selection: Binding(
          get: { DemoPhase(model.phase) },
          set: { model.show($0.presentation(origin: failureOrigin)) }
        )
      ) {
        ForEach(DemoPhase.allCases, id: \.self) { Text($0.rawValue).tag($0) }
      }
      Picker("Failure origin", selection: $failureOrigin) {
        Text("Browser").tag(RivetLoginFailure.Origin.browser)
        Text("PAT").tag(RivetLoginFailure.Origin.token)
      }
      .onChange(of: failureOrigin) { _, value in
        if case .failure = model.phase { model.show(DemoPhase.failure.presentation(origin: value)) }
      }
      Toggle("Simulate a failure", isOn: $model.shouldFail)
      Button("Simulate return to Rivet", action: model.simulateReturn)
        .disabled(model.phase != .waitingForBrowser)
      Button("Complete simulation", action: model.completeSimulation)
        .disabled(model.phase != .verifyingAccount && model.phase != .verifyingToken)
      Divider()
      Button("Reset demonstration", action: model.reset)
    }
    .padding(20).frame(width: 310, alignment: .leading)
  }
}
