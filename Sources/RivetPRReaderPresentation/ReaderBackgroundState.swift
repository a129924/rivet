import RivetPRReader

package enum ReaderBackgroundState: Equatable, Sendable {
  case idle
  case selected(ReaderPullRequestID)
  case loading(ReaderPullRequestID)
  case loaded(ReaderPullRequestID, ReaderBackground)
  case refreshing(ReaderPullRequestID, previous: ReaderBackground)
  case refreshFailed(ReaderPullRequestID, previous: ReaderBackground, failure: PRReaderFailure)
  case failed(ReaderPullRequestID, PRReaderFailure)

  var selectedID: ReaderPullRequestID? {
    switch self {
    case .idle:
      nil
    case .selected(let id), .loading(let id), .loaded(let id, _), .refreshing(let id, _),
      .refreshFailed(let id, _, _), .failed(let id, _):
      id
    }
  }

  var lastBackground: ReaderBackground? {
    switch self {
    case .loaded(_, let background), .refreshing(_, let background),
      .refreshFailed(_, let background, _):
      background
    case .idle, .selected, .loading, .failed:
      nil
    }
  }
}
