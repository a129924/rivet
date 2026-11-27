import Accessibility
import RivetPresentation
import SwiftUI

@MainActor
public struct InboxExperimentWorkspace<Controls: View, Notice: View>: View {
  private let header: InboxHeaderPresentation
  private let session: InboxExperimentSession
  private let load: () async -> InboxExperimentSession.LoadResult
  private let controls: Controls
  private let notice: Notice

  @State private var refreshID = 0
  @FocusState private var listFocused: Bool
  @FocusState private var statusFocused: Bool
  @AccessibilityFocusState(for: .voiceOver) private var spokenStatus: Bool

  public init(
    header: InboxHeaderPresentation,
    session: InboxExperimentSession,
    load: @escaping () async -> InboxExperimentSession.LoadResult,
    @ViewBuilder controls: () -> Controls,
    @ViewBuilder notice: () -> Notice
  ) {
    self.header = header
    self.session = session
    self.load = load
    self.controls = controls()
    self.notice = notice()
  }

  public var body: some View {
    InboxWorkspace(header: header, selectedFilter: .constant(.all), isFilterEnabled: false) {
      Label("Inbox", systemImage: "tray")
    } content: {
      VStack(spacing: 0) {
        if let status = session.snapshot.status {
          InboxListStatus(state: status)
            .focusable()
            .focused($statusFocused)
            .accessibilityFocused($spokenStatus)
            .accessibilityIdentifier("inbox-experiment-status")
        }
        notice
        if !session.snapshot.rows.isEmpty {
          PullRequestList(
            items: session.snapshot.rows,
            selection: Binding(
              get: { session.snapshot.selection },
              set: { session.select($0) }),
            focus: $listFocused,
            canOpen: { _ in false },
            onOpen: { _ in }
          )
          .listStyle(.plain)
          .accessibilityIdentifier("inbox-experiment-list")
        }
      }
    } footer: {
      HStack(spacing: 8) {
        controls
        Spacer()
        Button("重新整理") { refreshID += 1 }
          .keyboardShortcut("r")
          .disabled(session.snapshot.status == .loading)
          .accessibilityIdentifier("inbox-experiment-refresh")
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 9)
    }
    .task(id: refreshID) { await session.refresh(using: load) }
    .task(id: session.snapshot.status) {
      await Task.yield()
      guard !Task.isCancelled else { return }
      updateFocus()
    }
  }

  private func updateFocus() {
    guard let status = session.snapshot.status else {
      if !session.snapshot.rows.isEmpty {
        listFocused = true
      }
      return
    }
    if session.snapshot.rows.isEmpty {
      statusFocused = true
      spokenStatus = true
    } else {
      AccessibilityNotification.Announcement(status.title).post()
    }
  }
}
