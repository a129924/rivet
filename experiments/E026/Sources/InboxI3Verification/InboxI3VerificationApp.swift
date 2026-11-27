import Foundation
import InboxExperimentSupport
import RivetPresentation
import SwiftUI

// 2026-11-27T12:00:00Z
let inboxI3ReferenceDate = Date(timeIntervalSince1970: 1_795_780_800)

@main
struct InboxI3VerificationApp: App {
  var body: some Scene {
    Window("PR Inbox · I3 驗證", id: "inbox") {
      InboxI3VerificationView()
        .frame(minWidth: 420, minHeight: 390)
    }
    .defaultSize(width: 940, height: 560)
    .windowResizability(.contentMinSize)
  }
}

@MainActor
private struct InboxI3VerificationView: View {
  @State private var session = InboxExperimentSession()
  @State private var fixture: InboxI3Fixture = .candidates
  @State private var pageRelease: AsyncStream<Void>.Continuation?

  var body: some View {
    InboxExperimentWorkspace(
      header: InboxHeaderPresentation(
        title: "PR Inbox", subtitle: "挑選你開啟、待自查的 Pull Request"),
      session: session,
      load: load
    ) {
      Picker("受控情境", selection: $fixture) {
        ForEach(InboxI3Fixture.allCases) { value in
          Text(value.label).tag(value)
        }
      }
      .pickerStyle(.menu)
      .disabled(session.snapshot.status == .loading)
      .accessibilityIdentifier("i3-fixture")
      if let pageRelease {
        Button("完成第二頁") { pageRelease.finish() }
          .accessibilityIdentifier("i3-release-page")
      }
    } notice: {
      if pageRelease != nil {
        Text("已到第二頁，等待驗證")
          .font(.caption)
          .foregroundStyle(.secondary)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal, 12)
      }
    }
  }

  private func load() async -> InboxExperimentSession.LoadResult {
    let pages = AsyncStream<Void>.makeStream()
    let rest = InboxI3FixtureREST(fixture: fixture) {
      await waitForSecondPage(pages)
    }
    defer {
      pages.continuation.finish()
      pageRelease = nil
    }
    return await loadInboxI3(using: rest, referenceDate: inboxI3ReferenceDate)
  }

  private func waitForSecondPage(
    _ pages: (
      stream: AsyncStream<Void>, continuation: AsyncStream<Void>.Continuation
    )
  ) async {
    pageRelease = pages.continuation
    var iterator = pages.stream.makeAsyncIterator()
    _ = await iterator.next()
  }
}
