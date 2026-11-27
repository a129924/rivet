import Accessibility
import AppKit
import Foundation
import RivetPresentation
import SwiftUI

struct InboxWindow: View {
  @Binding var command: InboxCommand?
  @State private var session = InboxSession(trace: writeTrace)
  @State private var appearance: ColorScheme?
  @State private var selectedFilter: InboxHeaderFilter = .all
  @State private var isFilterEnabled = false
  @State private var showsLongTitle = false
  @State private var focusRequest = FocusRequest(target: .list)
  @FocusState private var listFocused: Bool
  @FocusState private var otherFocus: InboxFocus?
  @AccessibilityFocusState(for: .voiceOver) private var statusFocused: Bool

  private struct FocusRequest: Equatable {
    let target: InboxFocus
    let id = UUID()
  }

  private var focus: InboxFocus? { listFocused ? .list : otherFocus }

  var body: some View {
    InboxWorkspace(
      header: InboxHeaderPresentation(
        title: "PR Inbox", subtitle: "挑選你開啟、待自查的 Pull Request"
      ),
      selectedFilter: $selectedFilter,
      isFilterEnabled: isFilterEnabled
    ) {
      sidebar
    } content: {
      content
    } footer: {
      verification
    }
    .frame(minWidth: 420, minHeight: 390)
    .onGeometryChange(for: CGFloat.self) {
      $0.size.width
    } action: { width in
      Self.writeEvidence(LayoutSample(region: "workspace", widthPoints: width))
    }
    .background(
      InboxBoundaryKeys { edge in
        guard listFocused else { return false }
        let rows = session.rows
        guard let item = edge == .first ? rows.first : rows.last else { return false }
        session.select(item.id, focus: .list)
        return true
      }
    )
    .preferredColorScheme(appearance)
    .onChange(of: command) { _, command in
      if let command { perform(command) }
    }
    .onChange(of: focus, initial: true) { _, focus in
      session.observedFocus(focus)
    }
    .task(id: focusRequest) { [focusRequest] in
      await Task.yield()
      guard !Task.isCancelled, self.focusRequest == focusRequest else { return }
      applyFocus(focusRequest.target)
    }
  }

  private var sidebar: some View {
    VStack(alignment: .leading, spacing: 4) {
      Label("Inbox", systemImage: "tray")
        .font(.body.weight(.medium))
      Text("Repositories")
        .font(.caption.weight(.semibold))
        .accessibilityAddTraits(.isHeader)
      Text("sample/core · sample/ui")
        .font(.caption)
    }
  }

  private var content: some View {
    VStack(spacing: 0) {
      if let status = session.status {
        statusView(status)
        if !session.rows.isEmpty { Divider() }
      }
      if !session.rows.isEmpty {
        PullRequestList(
          items: session.rows.map(displayRow),
          selection: Binding(
            get: { session.selection },
            set: { session.select($0, focus: focus) }
          ),
          focus: $listFocused,
          canOpen: session.canOpen,
          onOpen: { session.open($0, focus: focus) }
        )
        .onGeometryChange(for: CGFloat.self) {
          $0.size.width
        } action: { width in
          Self.writeEvidence(LayoutSample(region: "list", widthPoints: width))
        }
      }
    }
  }

  private func displayRow(_ row: PullRequestRowPresentation) -> PullRequestRowPresentation {
    guard showsLongTitle, row.id == InboxFixture.rowB.id else { return row }
    return PullRequestRowPresentation(
      id: row.id,
      title: "整理工作台的鍵盤操作，保留各個原生控制項的焦點、選取與可及性",
      repositoryLabel: row.repositoryLabel,
      numberLabel: row.numberLabel,
      authorLabel: row.authorLabel,
      relativeTimeLabel: row.relativeTimeLabel,
      contextLabel: row.contextLabel,
      secondaryMetadataLabels: row.secondaryMetadataLabels
    )
  }

  private func statusView(_ status: InboxStatus) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(status.title)
        .font(.headline)
        .focusable()
        .focused($otherFocus, equals: .heading)
        .accessibilityAddTraits(.isHeader)
        .accessibilityValue(status.spokenDetail)
        .accessibilityFocused($statusFocused)
      if let detail = status.detail {
        Text(detail)
          .foregroundStyle(.secondary)
      }
      if let recovery = status.recovery {
        Button(recovery) {}
          .disabled(true)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(16)
  }

  private var verification: some View {
    HStack {
      Text("Open 事件：\(session.openCount)")
        .monospacedDigit()
      Spacer()
      if let lastOpen = session.lastOpen {
        Text(verbatim: lastOpen)
      }
    }
    .font(.caption)
    .foregroundStyle(.secondary)
    .padding(.horizontal, 16)
    .padding(.vertical, 8)
    .accessibilityElement(children: .combine)
    .focusable()
    .focused($otherFocus, equals: .verification)
  }

  private func applyFocus(_ target: InboxFocus) {
    if target == .list {
      otherFocus = nil
      listFocused = true
    } else {
      listFocused = false
      otherFocus = target
    }
    statusFocused = target == .heading
  }

  private func perform(_ command: InboxCommand) {
    self.command = nil
    switch command {
    case .scenario(let scenario):
      let destination = session.show(scenario, focus: focus)
      focusRequest = FocusRequest(target: destination)
      guard destination != .heading, let status = session.status else { return }
      AccessibilityNotification.Announcement(
        [status.title, status.spokenDetail].filter { !$0.isEmpty }.joined(separator: "。")
      ).post()
    case .focusVerification:
      focusRequest = FocusRequest(target: .verification)
    case .injectRemovedB:
      let removedID = InboxFixture.rowB.id
      if !session.rows.contains(where: { $0.id == removedID }) {
        session.open(removedID, focus: focus, injected: true)
      }
    case .appearance(let appearance):
      self.appearance = appearance
    case .togglePicker:
      isFilterEnabled.toggle()
    case .toggleLongTitle:
      showsLongTitle.toggle()
    case .width(let width):
      if let window = NSApp.keyWindow, let contentSize = window.contentView?.frame.size {
        window.setContentSize(NSSize(width: width, height: contentSize.height))
      }
    }
  }

  private struct LayoutSample: Encodable {
    let action = "layout"
    let region: String
    let widthPoints: CGFloat
  }

  private static func writeTrace(_ trace: InboxTrace) {
    writeEvidence(trace)
  }

  private static func writeEvidence(_ evidence: some Encodable) {
    guard var line = try? JSONEncoder().encode(evidence) else { return }
    line.append(0x0A)
    FileHandle.standardOutput.write(line)
  }
}
