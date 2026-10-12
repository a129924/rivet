import AppKit
import Foundation
import RivetPRReaderWebViewBridge
import WebKit

/// A fixture-only Presentation host. The bridge owns snapshot identity;
/// this host owns page lifetime.
@MainActor
public final class ReaderHarness: NSObject {
  public let window: NSWindow
  public let webView: WKWebView
  public let authority = HarnessViewedAuthority()
  private let messageHandler: WeakMessageHandler
  private let statusLabel = NSTextField(labelWithString: "正在載入本地 Reader fixture…")
  private lazy var bridge = BridgeSession(authority: authority, sink: self)
  private var generation = 0
  private var pendingSnapshotId: String?
  private var renderedSnapshotId: String?
  private var awaitingReady = false
  private var timeout: Task<Void, Never>?
  private var fixtureURL: URL?
  var resourceIndexURLOverride: URL?
  var readyTimeoutInterval: Duration = .seconds(15)
  var renderTimeoutInterval: Duration = .seconds(15)
  private(set) var rejectedNavigationCount = 0
  var visibleStatus: String { statusLabel.stringValue }
  var currentGeneration: Int { generation }
  var currentSnapshotId: String? { renderedSnapshotId }

  public override init() {
    let configuration = WKWebViewConfiguration()
    configuration.defaultWebpagePreferences.allowsContentJavaScript = true
    let handler = WeakMessageHandler()
    configuration.userContentController.add(handler, name: "rivet")
    messageHandler = handler
    webView = WKWebView(frame: .zero, configuration: configuration)
    window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 1024, height: 760),
      styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false
    )
    super.init()
    // The weak forwarder prevents WKUserContentController from retaining the host.
    messageHandler.target = self
    webView.navigationDelegate = self
    let content = NSView()
    window.contentView = content
    window.title = "Rivet PR Reader — 本地 fixture"
    webView.translatesAutoresizingMaskIntoConstraints = false
    statusLabel.translatesAutoresizingMaskIntoConstraints = false
    statusLabel.drawsBackground = true
    statusLabel.backgroundColor = .windowBackgroundColor
    statusLabel.font = .systemFont(ofSize: 12)
    statusLabel.textColor = .secondaryLabelColor
    content.addSubview(webView)
    content.addSubview(statusLabel)
    NSLayoutConstraint.activate([
      statusLabel.topAnchor.constraint(equalTo: content.topAnchor),
      statusLabel.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 12),
      statusLabel.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -12),
      statusLabel.heightAnchor.constraint(equalToConstant: 32),
      webView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor),
      webView.leadingAnchor.constraint(equalTo: content.leadingAnchor),
      webView.trailingAnchor.constraint(equalTo: content.trailingAnchor),
      webView.bottomAnchor.constraint(equalTo: content.bottomAnchor),
    ])
    authority.onSuccessfulWrite = { [weak self] in
      guard let self else { return }
      let acceptedGeneration = self.generation
      Task { @MainActor [weak self] in
        await Task.yield()
        guard let self, self.generation == acceptedGeneration else { return }
        self.publishFixture()
      }
    }
  }

  public func start(showWindow: Bool = true) {
    if showWindow { window.makeKeyAndOrderFront(nil) }
    guard
      let index = resourceIndexURLOverride
        ?? Bundle.module.url(forResource: "index", withExtension: "html"),
      Bundle.module.url(forResource: "reader", withExtension: "css") != nil,
      Bundle.module.url(forResource: "reader", withExtension: "js") != nil
    else {
      fail("資源載入失敗：Reader 資產缺失")
      return
    }
    fixtureURL = index
    webView.loadFileURL(index, allowingReadAccessTo: index.deletingLastPathComponent())
  }

  public func receiveSnapshot(_ snapshot: DiffSnapshotWire) throws {
    guard fixtureURL != nil, !webView.isLoading else { throw HarnessDeliveryFailure.pageNotReady }
    let encoded = try JSONEncoder().encode(snapshot)
    let base64 = encoded.base64EncodedString()
    let currentGeneration = generation
    pendingSnapshotId = snapshot.snapshotId
    renderedSnapshotId = nil
    setStatus("正在呈現 \(snapshot.files.count) 個檔案…")
    startTimeout(generation: currentGeneration, snapshotId: snapshot.snapshotId)
    let script =
      "window.rivet.receiveSnapshot(JSON.parse(new TextDecoder().decode("
      + "Uint8Array.from(atob('\(base64)'), c => c.charCodeAt(0)))), " + "\(currentGeneration))"
    webView.evaluateJavaScript(script) { [weak self] _, error in
      guard error != nil else { return }
      Task { @MainActor [weak self] in
        guard let self, self.generation == currentGeneration,
          self.pendingSnapshotId == snapshot.snapshotId
        else { return }
        self.fail("交付失敗：JavaScript 無法接收快照")
      }
    }
  }

  public func webView(
    _ webView: WKWebView,
    didStartProvisionalNavigation navigation: WKNavigation!
  ) {
    generation += 1
    bridge.invalidate()
    pendingSnapshotId = nil
    renderedSnapshotId = nil
    awaitingReady = true
    timeout?.cancel()
    setStatus("正在載入本地 Reader fixture…")
    startReadyTimeout(generation: generation)
  }

  public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    let currentGeneration = generation
    webView.evaluateJavaScript("window.rivet.start(\(currentGeneration))") { [weak self] _, error in
      guard error != nil else { return }
      Task { @MainActor [weak self] in
        guard let self, self.generation == currentGeneration else { return }
        self.fail("啟動失敗：Reader JavaScript 無法執行")
      }
    }
  }

  public func webView(
    _ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error
  ) {
    fail("資源載入失敗：Reader 頁面無法開啟")
  }

  public func webView(
    _ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!,
    withError error: Error
  ) {
    fail("資源載入失敗：Reader 頁面無法開啟")
  }

  public func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
    bridge.invalidate()
    fail("執行失敗：WebView process 已終止")
  }

  public func webView(
    _ webView: WKWebView,
    decidePolicyFor navigationAction: WKNavigationAction,
    decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void
  ) {
    let allowed =
      navigationAction.request.url == fixtureURL
      && navigationAction.targetFrame?.isMainFrame == true
    if !allowed { rejectedNavigationCount += 1 }
    decisionHandler(allowed ? .allow : .cancel)
  }

  public func userContentController(
    _ userContentController: WKUserContentController,
    didReceive message: WKScriptMessage
  ) {
    guard message.name == "rivet", let body = message.body as? [String: Any],
      let eventGeneration = body["generation"] as? Int, eventGeneration == generation,
      let kind = body["kind"] as? String
    else { return }
    switch kind {
    case "ready":
      guard awaitingReady else { return }
      awaitingReady = false
      timeout?.cancel()
      publishFixture()
    case "renderResult":
      guard let snapshotId = body["snapshotId"] as? String,
        snapshotId == pendingSnapshotId
      else { return }
      timeout?.cancel()
      pendingSnapshotId = nil
      if body["outcome"] as? String == "success" {
        renderedSnapshotId = snapshotId
        setStatus("本地 fixture · 已呈現 · Viewed 狀態由 Swift 管理")
      } else {
        let errorKind = body["outcome"] as? String ?? "unknown"
        fail("呈現失敗：\(errorKind)")
      }
    case "viewed":
      guard pendingSnapshotId == nil,
        let pullRequestId = body["pullRequestId"] as? String,
        let snapshotId = body["snapshotId"] as? String,
        snapshotId == renderedSnapshotId,
        let fileId = body["fileId"] as? String,
        let viewed = body["viewed"] as? Bool
      else { return }
      bridge.receiveViewedChange(
        .init(
          pullRequestId: pullRequestId, snapshotId: snapshotId,
          fileId: fileId, viewed: viewed))
    default:
      return
    }
  }

  private func publishFixture() {
    do {
      _ = try bridge.publish(ReaderFixture.snapshot)
    } catch {
      fail("交付失敗：無法建立或發送 Reader 快照")
    }
  }

  private func startTimeout(generation: Int, snapshotId: String) {
    timeout?.cancel()
    let interval = renderTimeoutInterval
    timeout = Task { @MainActor [weak self] in
      try? await Task.sleep(for: interval)
      guard let self, !Task.isCancelled, self.generation == generation,
        self.pendingSnapshotId == snapshotId
      else { return }
      self.fail("呈現逾時：Reader 未完成快照")
    }
  }

  private func startReadyTimeout(generation: Int) {
    timeout?.cancel()
    let interval = readyTimeoutInterval
    timeout = Task { @MainActor [weak self] in
      try? await Task.sleep(for: interval)
      guard let self, !Task.isCancelled, self.generation == generation, self.awaitingReady
      else { return }
      self.fail("啟動逾時：Reader 頁面未就緒")
    }
  }

  private func setStatus(_ message: String) {
    statusLabel.textColor = .secondaryLabelColor
    statusLabel.stringValue = message
  }

  private func fail(_ message: String) {
    timeout?.cancel()
    awaitingReady = false
    pendingSnapshotId = nil
    renderedSnapshotId = nil
    bridge.invalidate()
    setStatus(message)
    statusLabel.textColor = .systemRed
  }
}

extension ReaderHarness: DiffSnapshotSink, WKNavigationDelegate, WKScriptMessageHandler {}

private enum HarnessDeliveryFailure: Error { case pageNotReady }

@MainActor private final class WeakMessageHandler: NSObject, WKScriptMessageHandler {
  weak var target: ReaderHarness?
  func userContentController(
    _ userContentController: WKUserContentController, didReceive message: WKScriptMessage
  ) {
    target?.userContentController(userContentController, didReceive: message)
  }
}
