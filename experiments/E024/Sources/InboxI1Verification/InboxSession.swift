import Foundation
import Observation
import RivetPresentation

enum InboxFixture {
  static let rowA = row("core", 42, "簡化專案設定", age: "昨天")
  static let rowB = row("ui", 42, "整理工作台的鍵盤操作", age: "2 小時前")
  static let rowC = row("ui", 43, "調整視窗的最小寬度", age: "3 天前")
  static let current = [rowA, rowB, rowC]

  private static func row(
    _ repository: String, _ number: Int, _ title: String, age: String
  ) -> PullRequestRowPresentation {
    let repository = "sample/\(repository)"
    return PullRequestRowPresentation(
      id: "\(repository)#\(number)", title: title, repositoryLabel: repository,
      numberLabel: "#\(number)", authorLabel: "alex", relativeTimeLabel: age
    )
  }
}

enum InboxScenario: String, CaseIterable {
  case content, reordered, removedB, unknownOpen, loading, empty
  case readableError, unreadableError, missingAvailability, readableOffline, offline

  var label: String {
    switch self {
    case .content: "清單 A、B、C"
    case .reordered: "重排為 B、A、C"
    case .removedB: "移除 B，顯示 A、C"
    case .unknownOpen: "B 的 Open 安全性未知"
    case .loading: "載入中"
    case .empty: "成功空清單"
    case .readableError: "錯誤，有可讀舊清單"
    case .unreadableError: "錯誤，無可讀資料"
    case .missingAvailability: "資料可用性未知"
    case .readableOffline: "離線，有可讀舊清單"
    case .offline: "離線，無可讀資料"
    }
  }

  var content: [PullRequestRowPresentation]? {
    switch self {
    case .content, .unknownOpen: InboxFixture.current
    case .reordered: [InboxFixture.rowB, InboxFixture.rowA, InboxFixture.rowC]
    case .removedB: [InboxFixture.rowA, InboxFixture.rowC]
    case .empty: []
    default: nil
    }
  }
}

enum InboxFocus: String, Equatable, Codable {
  case list, heading, verification
}

struct InboxStatus {
  let title: String
  let detail: String?
  let recovery: String?

  init(_ title: String, detail: String? = nil, recovery: String? = nil) {
    self.title = title
    self.detail = detail
    self.recovery = recovery
  }

  var spokenDetail: String {
    [detail, recovery.map { "\($0)目前無法使用" }].compactMap { $0 }.joined(separator: "。")
  }
}

struct InboxTrace: Encodable {
  let action: String
  let scenario: String
  let previousSelection: String?
  let selection: String?
  let focus: InboxFocus?
  let requestedFocus: InboxFocus?
  let target: String?
  let openID: String?
  let openCount: Int
  let openDelta: Int
}

@MainActor @Observable
final class InboxSession {
  private(set) var scenario: InboxScenario = .content
  private(set) var selectedIdentity: String? = InboxFixture.rowA.id
  private(set) var openCount = 0
  private(set) var lastOpen: String?
  private var lastReadableRows = InboxFixture.current
  private let trace: @MainActor (InboxTrace) -> Void

  init(trace: @escaping @MainActor (InboxTrace) -> Void = { _ in }) {
    self.trace = trace
  }

  var rows: [PullRequestRowPresentation] {
    switch scenario {
    case .readableError, .readableOffline: lastReadableRows
    default: scenario.content ?? []
    }
  }

  var selection: String? {
    rows.first { $0.id == selectedIdentity }?.id
  }

  var status: InboxStatus? {
    switch scenario {
    case .content, .reordered, .removedB, .unknownOpen:
      nil
    case .loading:
      InboxStatus("正在載入 Pull Requests")
    case .empty:
      InboxStatus("沒有待自查的 Pull Request")
    case .readableError, .unreadableError, .missingAvailability:
      InboxStatus(
        "暫時無法取得 Pull Requests",
        detail: rows.isEmpty ? "目前沒有可讀資料" : "正在顯示舊清單，內容可能非最新",
        recovery: "重試"
      )
    case .readableOffline, .offline:
      InboxStatus(
        "目前離線",
        detail: rows.isEmpty ? "目前沒有可讀資料" : "正在顯示舊清單，內容可能非最新",
        recovery: "重新連線"
      )
    }
  }

  func canOpen(_ id: String) -> Bool {
    guard let content = scenario.content, content.contains(where: { $0.id == id })
    else { return false }
    return id != InboxFixture.rowC.id && !(scenario == .unknownOpen && id == InboxFixture.rowB.id)
  }

  @discardableResult
  func show(_ next: InboxScenario, focus: InboxFocus?) -> InboxFocus {
    let previous = selection
    scenario = next
    if let content = next.content { lastReadableRows = content }
    if let first = rows.first, selection == nil { selectedIdentity = first.id }

    let destination: InboxFocus
    switch next {
    case .loading:
      destination = focus == .verification ? .verification : .heading
    case .readableError:
      destination = rows.isEmpty ? .heading : (focus ?? .heading)
    default:
      destination = rows.isEmpty ? .heading : .list
    }
    record("scenario", from: previous, focus: focus, requestedFocus: destination)
    return destination
  }

  func select(_ id: String?, focus: InboxFocus?) {
    guard let id, id != selection, rows.contains(where: { $0.id == id }) else { return }
    let previous = selection
    selectedIdentity = id
    record("selection", from: previous, focus: focus)
  }

  @discardableResult
  func open(_ id: String, focus: InboxFocus?, injected: Bool = false) -> Bool {
    let accepted = selection == id && canOpen(id)
    if accepted {
      openCount += 1
      lastOpen = id
    }
    record(
      injected ? "injectedOpen" : "openIntent", from: selection, focus: focus, target: id,
      opened: accepted ? id : nil
    )
    return accepted
  }

  func observedFocus(_ focus: InboxFocus?) {
    record("focus", from: selection, focus: focus)
  }

  private func record(
    _ action: String, from previous: String?, focus: InboxFocus?, requestedFocus: InboxFocus? = nil,
    target: String? = nil, opened: String? = nil
  ) {
    trace(
      InboxTrace(
        action: action, scenario: scenario.rawValue, previousSelection: previous,
        selection: selection, focus: focus, requestedFocus: requestedFocus, target: target,
        openID: opened, openCount: openCount, openDelta: opened == nil ? 0 : 1
      )
    )
  }
}
