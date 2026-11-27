import Observation
import RivetPRInbox

struct InboxRow: Identifiable, Equatable {
  struct Identity: Hashable {
    let owner: String
    let repository: String
    let number: Int
  }

  let id: Identity
  let title: String

  init(_ item: InboxItem) {
    id = Identity(owner: item.owner, repository: item.repository, number: item.number)
    title = item.title
  }

  var repositoryLabel: String { "\(id.owner)/\(id.repository)" }
  var numberLabel: String { "#\(id.number)" }
}

enum InboxLoadResult: Sendable {
  case success([InboxItem], viewer: String? = nil)
  case unavailable
  case liveNotRun(LivePrecondition)
}

enum LivePrecondition: String, Sendable {
  case missingConfiguration
  case notSignedIn
  case authenticationRequired
  case restoreFailed
}

@MainActor @Observable
final class InboxSession {
  enum Status: Equatable {
    case initial, loading, ready, empty, unavailable, stale
    case liveNotRun(LivePrecondition)
  }

  struct Snapshot: Equatable {
    var status: Status = .initial
    var rows: [InboxRow] = []
    var selection: InboxRow.Identity?
    var viewer: String?
  }

  private(set) var snapshot = Snapshot()

  func select(_ id: InboxRow.Identity?) {
    guard let id, snapshot.rows.contains(where: { $0.id == id }) else { return }
    snapshot.selection = id
  }

  func refresh(
    using load: @Sendable () async -> InboxLoadResult
  ) async {
    guard snapshot.status != .loading else { return }
    let previous = snapshot
    snapshot.status = .loading
    let outcome = await load()
    guard !Task.isCancelled else {
      snapshot.status = previous.status
      return
    }
    switch outcome {
    case .success(let items, let viewer):
      let rows = items.map(InboxRow.init)
      let oldSelection = snapshot.selection
      let selection = rows.first { $0.id == oldSelection }?.id ?? rows.first?.id
      snapshot = Snapshot(
        status: rows.isEmpty ? .empty : .ready, rows: rows, selection: selection, viewer: viewer)
    case .unavailable:
      snapshot.status = snapshot.rows.isEmpty ? .unavailable : .stale
    case .liveNotRun(let reason):
      snapshot = Snapshot(status: .liveNotRun(reason))
    }
  }
}
