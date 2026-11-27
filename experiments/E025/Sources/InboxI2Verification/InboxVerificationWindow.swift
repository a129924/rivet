import RivetPresentation
import SwiftUI

struct InboxVerificationWindow: View {
  let mode: InboxVerificationMode

  @State private var session = InboxSession()
  @State private var fixture: InboxFixture
  @State private var refreshID = 0
  @State private var pageRelease: AsyncStream<Void>.Continuation?

  init(mode: InboxVerificationMode) {
    self.mode = mode
    _fixture = State(initialValue: mode.initialFixture)
  }

  var body: some View {
    InboxWorkspace(
      header: InboxHeaderPresentation(
        title: "PR Inbox", subtitle: "挑選你開啟、待自查的 Pull Request"),
      selectedFilter: .constant(.all),
      isFilterEnabled: false
    ) {
      Label("Inbox", systemImage: "tray")
    } content: {
      VStack(spacing: 0) {
        if let message = statusMessage {
          Text(message)
            .font(.headline)
            .accessibilityAddTraits(.isHeader)
            .accessibilityIdentifier("i2-status")
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
        }
        if !session.snapshot.rows.isEmpty {
          inboxList
        }
      }
    } footer: {
      footer
    }
    .task(id: refreshID) { await refresh() }
  }

  private var inboxList: some View {
    List(
      selection: Binding(
        get: { session.snapshot.selection },
        set: { session.select($0) })
    ) {
      ForEach(session.snapshot.rows) { row in
        VStack(alignment: .leading, spacing: 3) {
          Text(verbatim: row.title)
            .font(.headline)
            .lineLimit(1)
          Text(verbatim: "\(row.repositoryLabel) \(row.numberLabel)")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
          Text(verbatim: "\(row.title), \(row.repositoryLabel) \(row.numberLabel)")
        )
        .accessibilityIdentifier("i2-row-\(row.repositoryLabel)-\(row.id.number)")
        .padding(.vertical, 4)
        .tag(row.id)
      }
    }
    .listStyle(.plain)
    .accessibilityIdentifier("i2-list")
  }

  private var footer: some View {
    HStack(spacing: 8) {
      switch mode {
      case .controlled:
        Picker("受控情境", selection: $fixture) {
          ForEach(InboxFixture.allCases) { value in
            Text(value.label).tag(value)
          }
        }
        .pickerStyle(.menu)
        .disabled(session.snapshot.status == .loading)
        .accessibilityIdentifier("i2-fixture")
      case .live:
        if let viewer = session.snapshot.viewer {
          Text(verbatim: "OAuth 帳號 \(viewer)")
            .accessibilityIdentifier("i2-viewer")
        }
      }
      Spacer()
      if let pageRelease {
        Button("讓第二頁失敗") { pageRelease.finish() }
          .accessibilityIdentifier("i2-release-page")
      }
      Button("重新整理") { refreshID += 1 }
        .keyboardShortcut("r")
        .disabled(session.snapshot.status == .loading)
        .accessibilityIdentifier("i2-refresh")
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 9)
  }

  private var statusMessage: String? {
    switch session.snapshot.status {
    case .initial, .ready: nil
    case .loading:
      pageRelease == nil ? "正在取得 Pull Request…" : "已到第二頁，等待驗證"
    case .empty: "目前沒有待自查的 Pull Request"
    case .unavailable: "無法取得 Pull Request"
    case .stale: "更新失敗。清單可能不是最新的。"
    case .liveNotRun(let reason):
      switch reason {
      case .missingConfiguration: "真人驗收未執行。此 App 未配置既有 OAuth 工作階段。"
      case .notSignedIn: "真人驗收未執行。找不到既有 OAuth 工作階段。"
      case .authenticationRequired: "真人驗收未執行。既有 OAuth 工作階段已無法使用。"
      case .restoreFailed: "真人驗收未執行。無法還原既有 OAuth 工作階段。"
      }
    }
  }

  private func refresh() async {
    switch mode {
    case .controlled:
      let pages = AsyncStream<Void>.makeStream()
      let fixtureREST = FixtureREST(fixture: fixture) {
        await markSecondPage(pages.continuation)
        var iterator = pages.stream.makeAsyncIterator()
        _ = await iterator.next()
      }
      await session.refresh { await loadInbox(using: fixtureREST) }
      pageRelease = nil
    case .live(let connection):
      await session.refresh { await connection.refresh() }
    }
  }

  private func markSecondPage(_ release: AsyncStream<Void>.Continuation) {
    pageRelease = release
  }
}
