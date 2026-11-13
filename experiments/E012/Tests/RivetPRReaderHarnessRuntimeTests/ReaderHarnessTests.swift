import AppKit
import Foundation
import RivetPRReader
import RivetPRReaderWebViewBridge
import Testing
import WebKit

@testable import RivetPRReaderHarnessRuntime

@Suite("Reader harness authority") @MainActor struct ReaderHarnessTests {
  @Test func fixtureHasOrderedSixStatesAndMetadataOnlyFiles() {
    let files = ReaderFixture.snapshot.files
    #expect(files.map(\.change) == [.added, .removed, .modified, .renamed, .copied, .typeChanged])
    #expect(files.count == 6)
    #expect(files.contains { $0.patch == nil })
  }

  @Test func successfulAuthorityWriteNotifiesAndFailureDoesNot() throws {
    let authority = HarnessViewedAuthority()
    let pullRequest = ReaderFixture.snapshot.id
    let first = ReaderFixture.snapshot.files[0].reference
    let second = ReaderFixture.snapshot.files[1].reference
    var notifications = 0
    authority.onSuccessfulWrite = { notifications += 1 }
    try authority.setViewed(true, for: pullRequest, file: first)
    #expect(try authority.viewed(for: pullRequest, file: first))
    #expect(try !authority.viewed(for: pullRequest, file: second))
    #expect(notifications == 1)
    #expect(throws: HarnessAuthorityFailure.invalidIdentity) {
      try authority.setViewed(
        true, for: .init(owner: "wrong", repository: "wrong", number: 0), file: first)
    }
    #expect(notifications == 1)
  }

  @Test func bridgeIgnoresStaleChangeBeforeAuthorityCallback() throws {
    let authority = HarnessViewedAuthority()
    let sink = HarnessSinkSpy()
    let session = BridgeSession(authority: authority, sink: sink)
    var notifications = 0
    authority.onSuccessfulWrite = { notifications += 1 }
    let first = try session.publish(ReaderFixture.snapshot)
    _ = try session.publish(ReaderFixture.snapshot)
    session.receiveViewedChange(
      .init(
        pullRequestId: first.pullRequestId, snapshotId: first.snapshotId, fileId: "f:0",
        viewed: true))
    #expect(notifications == 0)
  }

  @Test func realWebViewRendersFixtureAndViewedRoundTrip() async throws {
    _ = NSApplication.shared
    let harness = ReaderHarness()
    harness.start(showWindow: false)
    try await waitUntil(in: harness) {
      harness.visibleStatus.contains("已呈現")
    }
    let detailsScript =
      "JSON.stringify(Array.from(document.querySelectorAll('.diff-file')).map(node => ("
      + "{id: node.dataset.fileId, name: node.querySelector('h2').textContent, "
      + "status: node.querySelector('.file-status').textContent})))"
    let details =
      try await harness.webView.evaluateJavaScript(detailsScript) as? String
    let data = try #require(details?.data(using: .utf8))
    let files = try JSONDecoder().decode([RenderedFile].self, from: data)
    #expect(files.map(\.id) == ["f:0", "f:1", "f:2", "f:3", "f:4", "f:5"])
    #expect(
      files.map(\.status) == ["added", "removed", "modified", "renamed", "copied", "typeChanged"])
    #expect(files.first?.name == "Sources/NewFeature.swift")
    let metadataCount =
      try await harness.webView.evaluateJavaScript(
        "document.querySelectorAll('.metadata-note').length") as? Int
    #expect(metadataCount == 2)
    let patchCount =
      try await harness.webView.evaluateJavaScript("document.querySelectorAll('.patch').length")
      as? Int
    #expect(patchCount == 4)
    let executableImages =
      try await harness.webView.evaluateJavaScript("document.querySelectorAll('.patch img').length")
      as? Int
    #expect(executableImages == 0)
    let injected =
      try await harness.webView.evaluateJavaScript("window.__rivetInjected === true") as? Bool
    #expect(injected == false)

    _ = try await harness.webView.evaluateJavaScript(
      "document.querySelector('.viewed-button').click()")
    let first = ReaderFixture.snapshot.files[0].reference
    try await waitUntil(in: harness) {
      try harness.authority.viewed(for: ReaderFixture.snapshot.id, file: first)
    }
    try await waitForButton("已 Viewed · 取消", in: harness)

    _ = try await harness.webView.evaluateJavaScript(
      "document.querySelector('.viewed-button').click()")
    try await waitUntil(in: harness) {
      try !harness.authority.viewed(for: ReaderFixture.snapshot.id, file: first)
    }
    try await waitForButton("標記 Viewed", in: harness)
    let mismatchedChange =
      "window.rivet.requestViewedStateChange({pullRequestId:'wrong',"
      + "snapshotId:'old',fileId:'f:0',viewed:true})"
    _ = try await harness.webView.evaluateJavaScript(mismatchedChange)
    try await Task.sleep(for: .milliseconds(100))
    #expect(try !harness.authority.viewed(for: ReaderFixture.snapshot.id, file: first))
    let stale =
      [
        "kind": "viewed", "generation": harness.currentGeneration - 1,
        "pullRequestId": PullRequestIDEncoding.encode(ReaderFixture.snapshot.id),
        "snapshotId": try #require(harness.currentSnapshotId), "fileId": "f:0", "viewed": true,
      ] as [String: Any]
    let staleJSON = try #require(
      String(bytes: JSONSerialization.data(withJSONObject: stale), encoding: .utf8))
    _ = try await harness.webView.evaluateJavaScript(
      "window.webkit.messageHandlers.rivet.postMessage(\(staleJSON)); 0")
    try await Task.sleep(for: .milliseconds(100))
    #expect(try !harness.authority.viewed(for: ReaderFixture.snapshot.id, file: first))
  }

  @Test func realWebViewDisplaysRenderAndProcessFailures() async throws {
    _ = NSApplication.shared
    let harness = ReaderHarness()
    harness.start(showWindow: false)
    try await waitUntil(in: harness) { harness.visibleStatus.contains("已呈現") }
    try harness.receiveSnapshot(
      .init(
        pullRequestId: "pr", snapshotId: "invalid-fixture",
        files: [
          .init(
            fileId: "f:0", filename: "", previousFilename: nil, status: .modified,
            patch: nil, additions: 0, deletions: 0, viewed: false)
        ]))
    try await waitUntil(in: harness) {
      harness.visibleStatus.contains("呈現失敗：invalid-input")
    }
    harness.webViewWebContentProcessDidTerminate(harness.webView)
    #expect(harness.visibleStatus.contains("WebView process 已終止"))
  }

  @Test func missingReaderResourceDisplaysLoadFailure() async throws {
    _ = NSApplication.shared
    let harness = ReaderHarness()
    let missingIndex = FileManager.default.temporaryDirectory
      .appendingPathComponent("rivet-missing-\(UUID().uuidString).html")
    #expect(!FileManager.default.fileExists(atPath: missingIndex.path))
    harness.resourceIndexURLOverride = missingIndex
    harness.start(showWindow: false)
    try await waitUntil(in: harness) {
      harness.visibleStatus.contains("資源載入失敗")
    }
    #expect(harness.currentSnapshotId == nil)
  }

  @Test func realWebViewDisplaysSnapshotDeliveryFailure() async throws {
    _ = NSApplication.shared
    let harness = ReaderHarness()
    harness.start(showWindow: false)
    try await waitUntil(in: harness) { harness.visibleStatus.contains("已呈現") }
    _ = try await harness.webView.evaluateJavaScript("window.rivet = undefined; 0")
    try harness.receiveSnapshot(
      .init(pullRequestId: "pr", snapshotId: "delivery-failure", files: []))
    try await waitUntil(in: harness) {
      harness.visibleStatus.contains("交付失敗：JavaScript 無法接收快照")
    }
    #expect(harness.currentSnapshotId == nil)
  }

  @Test func realWebViewDisplaysRenderTimeout() async throws {
    _ = NSApplication.shared
    let harness = ReaderHarness()
    harness.start(showWindow: false)
    try await waitUntil(in: harness) { harness.visibleStatus.contains("已呈現") }
    harness.renderTimeoutInterval = .milliseconds(150)
    _ = try await harness.webView.evaluateJavaScript(
      "window.rivet.receiveSnapshot = function () {}; 0")
    try harness.receiveSnapshot(
      .init(pullRequestId: "pr", snapshotId: "render-timeout", files: []))
    try await waitUntil(in: harness) {
      harness.visibleStatus.contains("呈現逾時：Reader 未完成快照")
    }
    #expect(harness.currentSnapshotId == nil)
  }

  @Test func realWebViewDisplaysReadyTimeoutAndIgnoresLateReady() async throws {
    _ = NSApplication.shared
    let harness = ReaderHarness()
    harness.readyTimeoutInterval = .seconds(2)
    harness.webView.configuration.userContentController.addUserScript(suppressReadyScript())
    harness.start(showWindow: false)
    try await waitUntil(in: harness) {
      harness.webView.isLoading == false && harness.currentGeneration > 0
    }
    let suppressed =
      try await harness.webView.evaluateJavaScript(
        "window.__rivetReadySuppressed === true") as? Bool
    #expect(suppressed == true)
    try await waitUntil(in: harness) { harness.visibleStatus.contains("啟動逾時") }
    #expect(harness.currentSnapshotId == nil)
    let generation = harness.currentGeneration
    _ = try await harness.webView.evaluateJavaScript(
      "window.webkit.messageHandlers.rivet.postMessage({kind:'ready',generation:\(generation)}); 0")
    try await Task.sleep(for: .milliseconds(100))
    #expect(harness.visibleStatus.contains("啟動逾時"))
    #expect(harness.currentSnapshotId == nil)
  }

  @Test func oldReadyDeadlineCannotFailNewPageGeneration() async throws {
    _ = NSApplication.shared
    let harness = ReaderHarness()
    harness.readyTimeoutInterval = .seconds(2)
    harness.webView.configuration.userContentController.addUserScript(suppressReadyScript())
    harness.start(showWindow: false)
    try await waitUntil(in: harness) {
      harness.webView.isLoading == false && harness.currentGeneration > 0
    }
    let suppressed =
      try await harness.webView.evaluateJavaScript(
        "window.__rivetReadySuppressed === true") as? Bool
    #expect(suppressed == true)
    #expect(harness.visibleStatus.contains("正在載入"))
    let firstGeneration = harness.currentGeneration
    harness.webView.configuration.userContentController.removeAllUserScripts()
    harness.start(showWindow: false)
    try await waitUntil(in: harness) {
      harness.currentGeneration == firstGeneration + 1 && harness.visibleStatus.contains("已呈現")
    }
    try await Task.sleep(for: .milliseconds(2_200))
    #expect(harness.visibleStatus.contains("已呈現"))
    #expect(harness.currentSnapshotId != nil)
  }

  @Test func realWebViewRejectsExternalNavigation() async throws {
    _ = NSApplication.shared
    let harness = ReaderHarness()
    harness.start(showWindow: false)
    try await waitUntil(in: harness) { harness.visibleStatus.contains("已呈現") }
    let fixtureURL = try #require(harness.webView.url)
    #expect(harness.rejectedNavigationCount == 0)
    let externalURL = try #require(URL(string: "https://example.invalid/"))
    harness.webView.load(URLRequest(url: externalURL))
    try await waitUntil(in: harness) { harness.rejectedNavigationCount == 1 }
    try await Task.sleep(for: .milliseconds(100))
    #expect(harness.webView.url == fixtureURL)
    #expect(harness.visibleStatus.contains("已呈現"))
    let fileCount =
      try await harness.webView.evaluateJavaScript(
        "document.querySelectorAll('.diff-file').length") as? Int
    #expect(fileCount == 6)
  }

  private func waitUntil(in harness: ReaderHarness, condition: () throws -> Bool) async throws {
    for _ in 0..<100 {
      if try condition() { return }
      try await Task.sleep(for: .milliseconds(100))
    }
    Issue.record(
      "WKWebView did not reach the expected state within ten seconds; status: \(harness.visibleStatus)"
    )
    throw HarnessTestFailure.timeout
  }

  private func waitForButton(_ expected: String, in harness: ReaderHarness) async throws {
    for _ in 0..<100 {
      let actual =
        try await harness.webView.evaluateJavaScript(
          "document.querySelector('.viewed-button')?.textContent") as? String
      if actual == expected { return }
      try await Task.sleep(for: .milliseconds(100))
    }
    Issue.record("Viewed DOM did not refresh within ten seconds; status: \(harness.visibleStatus)")
    throw HarnessTestFailure.timeout
  }

  private func suppressReadyScript() -> WKUserScript {
    WKUserScript(
      source: "window.rivet.start = function () { window.__rivetReadySuppressed = true; };",
      injectionTime: .atDocumentEnd, forMainFrameOnly: true)
  }
}

private struct RenderedFile: Decodable {
  let id: String
  let name: String
  let status: String
}

private enum HarnessTestFailure: Error { case timeout }

@MainActor private final class HarnessSinkSpy: DiffSnapshotSink {
  func receiveSnapshot(_ snapshot: DiffSnapshotWire) throws {}
}
