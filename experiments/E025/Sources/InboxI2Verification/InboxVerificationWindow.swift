import Accessibility
import RivetPresentation
import SwiftUI

struct InboxVerificationWindow: View {
  let mode: InboxVerificationMode

  @State private var session = InboxSession()
  @State private var fixture: InboxFixture
  @State private var refreshID = 0
  @State private var pageRelease: AsyncStream<Void>.Continuation?
  @State private var hasShownList = false
  @FocusState private var listFocused: Bool
  @FocusState private var otherFocus: FocusTarget?
  @AccessibilityFocusState(for: .voiceOver) private var spokenStatus: InboxSession.Status?

  private enum FocusTarget: Hashable {
    case status(InboxSession.Status)
    case fixture, releasePage, refresh
  }

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
        statusContent
        if pageRelease != nil {
          Text("已到第二頁，等待驗證")
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
        }
        if !session.snapshot.rows.isEmpty {
          inboxList
        }
      }
    } footer: {
      footer
    }
    .task(id: refreshID) { await refresh() }
    .task(id: session.snapshot.status) {
      await Task.yield()
      guard !Task.isCancelled else { return }
      updateFocus()
    }
  }

  private var inboxList: some View {
    PullRequestList(
      items: session.snapshot.rows.map(\.presentation),
      selection: Binding(
        get: { session.presentationSelection },
        set: { session.select(presentationID: $0) }),
      focus: $listFocused,
      canOpen: { _ in false },
      onOpen: { _ in }
    )
    .listStyle(.plain)
    .accessibilityIdentifier("i2-list")
  }

  @ViewBuilder private var statusContent: some View {
    if let displayStatus {
      InboxListStatus(state: displayStatus)
        .focusable()
        .focused($otherFocus, equals: .status(session.snapshot.status))
        .accessibilityFocused($spokenStatus, equals: session.snapshot.status)
        .accessibilityIdentifier("i2-status")
    } else if case .liveNotRun(let reason) = session.snapshot.status {
      Text(liveStatusMessage(reason))
        .font(.headline)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .focusable()
        .focused($otherFocus, equals: .status(session.snapshot.status))
        .accessibilityFocused($spokenStatus, equals: session.snapshot.status)
        .accessibilityAddTraits(.isHeader)
        .accessibilityIdentifier("i2-status")
    }
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
        .focused($otherFocus, equals: .fixture)
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
          .focused($otherFocus, equals: .releasePage)
          .accessibilityIdentifier("i2-release-page")
      }
      Button("重新整理") { refreshID += 1 }
        .keyboardShortcut("r")
        .disabled(session.snapshot.status == .loading)
        .focused($otherFocus, equals: .refresh)
        .accessibilityIdentifier("i2-refresh")
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 9)
  }

  private var displayStatus: InboxListStatus.State? {
    switch session.snapshot.status {
    case .initial, .ready, .liveNotRun: nil
    case .loading: .loading
    case .empty: .empty
    case .unavailable: .unavailable
    case .stale: .stale
    }
  }

  private func updateFocus() {
    switch session.snapshot.status {
    case .initial:
      break
    case .loading, .stale:
      if listFocused || hasValidStatusTransitionFocus {
        announceStatus()
      } else {
        focusStatus()
      }
    case .ready:
      if !listFocused, !hasShownList || otherFocus == nil || statusHasFocus {
        otherFocus = nil
        spokenStatus = nil
        listFocused = true
      }
      hasShownList = true
    case .empty, .unavailable, .liveNotRun:
      focusStatus()
    }
  }

  private var statusHasFocus: Bool {
    if case .status = otherFocus { return true }
    return false
  }

  private var hasValidStatusTransitionFocus: Bool {
    switch otherFocus {
    case .status(let status): status == session.snapshot.status
    case .fixture, .refresh: session.snapshot.status != .loading
    case .releasePage: session.snapshot.status == .loading && pageRelease != nil
    case nil: false
    }
  }

  private func announceStatus() {
    if let displayStatus {
      AccessibilityNotification.Announcement(displayStatus.title).post()
    }
  }

  private func focusStatus() {
    listFocused = false
    otherFocus = .status(session.snapshot.status)
    spokenStatus = session.snapshot.status
  }

  private func liveStatusMessage(_ reason: LivePrecondition) -> String {
    switch reason {
    case .missingConfiguration: "真人驗收未執行。此 App 未配置既有 OAuth 工作階段。"
    case .notSignedIn: "真人驗收未執行。找不到既有 OAuth 工作階段。"
    case .authenticationRequired: "真人驗收未執行。既有 OAuth 工作階段已無法使用。"
    case .restoreFailed: "真人驗收未執行。無法還原既有 OAuth 工作階段。"
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
