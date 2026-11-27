import Observation
import RivetPresentation

@MainActor @Observable
public final class InboxExperimentSession {
  public typealias Row = PullRequestRowPresentation

  public enum LoadResult: Sendable {
    case success([Row])
    case unavailable
  }

  public struct Snapshot: Equatable {
    public fileprivate(set) var status: InboxListStatus.State?
    public fileprivate(set) var rows: [Row] = []
    public fileprivate(set) var selection: Row.ID?
  }

  public private(set) var snapshot = Snapshot()

  public init() {}

  public func select(_ id: Row.ID?) {
    guard let id, snapshot.rows.contains(where: { $0.id == id }) else { return }
    snapshot.selection = id
  }

  public func refresh(using load: () async -> LoadResult) async {
    guard snapshot.status != .loading, !Task.isCancelled else { return }
    let previousStatus = snapshot.status
    snapshot.status = .loading
    let result = await load()
    guard !Task.isCancelled else {
      snapshot.status = previousStatus
      return
    }

    switch result {
    case .success(let rows):
      let selection = rows.first { $0.id == snapshot.selection }?.id ?? rows.first?.id
      snapshot = Snapshot(status: rows.isEmpty ? .empty : nil, rows: rows, selection: selection)
    case .unavailable:
      snapshot.status = snapshot.rows.isEmpty ? .unavailable : .stale
    }
  }
}
