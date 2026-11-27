import SwiftUI

/// Presents the status supplied by the caller, which continues to own the list and its focus.
public struct InboxListStatus: View {
  public enum State: Equatable, Sendable {
    case loading
    case empty
    case unavailable
    case stale

    /// The visible heading, also suitable for a local accessibility announcement.
    public var title: String {
      switch self {
      case .loading: "正在取得 Pull Request…"
      case .empty: "目前沒有待自查的 Pull Request"
      case .unavailable: "無法取得 Pull Request"
      case .stale: "更新失敗。清單可能不是最新的。"
      }
    }
  }

  private let state: State

  public init(state: State) {
    self.state = state
  }

  public var body: some View {
    HStack(spacing: 8) {
      if state == .loading {
        ProgressView()
          .controlSize(.small)
          .accessibilityHidden(true)
      }
      Text(verbatim: state.title)
        .font(.headline)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(12)
    .accessibilityElement(children: .combine)
    .accessibilityAddTraits(.isHeader)
  }
}
