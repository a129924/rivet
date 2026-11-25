import Observation
import RivetPRReader

@MainActor
@Observable
package final class PRReaderBackgroundSession {
  private final class Token: Sendable {}

  private struct Request {
    let id: ReaderPullRequestID
    let token: Token
    let task: Task<Void, Never>
  }

  private let facade: PRReaderBackgroundFacade
  @ObservationIgnored private var request: Request?
  @ObservationIgnored private var invalidated = false
  @ObservationIgnored private var displayState: ReaderBackgroundState = .idle

  package var state: ReaderBackgroundState {
    access(keyPath: \.state)
    return displayState
  }

  package init(facade: PRReaderBackgroundFacade) {
    self.facade = facade
  }

  package func select(_ id: ReaderPullRequestID) {
    guard !invalidated, displayState.selectedID != id else { return }
    start(for: id, previous: nil)
  }

  package func refresh() {
    guard !invalidated, let id = displayState.selectedID else { return }
    start(for: id, previous: displayState.lastBackground)
  }

  package func cancelLoading() {
    guard let request else { return }
    self.request = nil
    restoreSelection(for: request.id)
    request.task.cancel()
  }

  package func invalidate() {
    guard !invalidated else { return }
    invalidated = true
    let task = request?.task
    request = nil
    publish(.idle)
    task?.cancel()
  }

  private func start(for id: ReaderPullRequestID, previous: ReaderBackground?) {
    let superseded = request?.task
    let token = Token()
    let task = Task { [weak self, facade] in
      let outcome = await facade.fetchBackground(for: id)
      self?.finish(outcome, for: id, token: token)
    }
    request = Request(id: id, token: token, task: task)
    publish(previous.map { .refreshing(id, previous: $0) } ?? .loading(id))
    superseded?.cancel()
  }

  private func finish(
    _ outcome: Outcome<ReaderBackground, PRReaderFailure>,
    for id: ReaderPullRequestID,
    token: Token
  ) {
    guard !invalidated, request?.token === token, displayState.selectedID == id else { return }
    request = nil
    if Task.isCancelled {
      restoreSelection(for: id)
      return
    }

    switch outcome {
    case .success(let background):
      publish(.loaded(id, background))
    case .failure(let failure):
      publish(
        displayState.lastBackground.map { .refreshFailed(id, previous: $0, failure: failure) }
          ?? .failed(id, failure)
      )
    }
  }

  private func restoreSelection(for id: ReaderPullRequestID) {
    publish(displayState.lastBackground.map { .loaded(id, $0) } ?? .selected(id))
  }

  private func publish(_ newState: ReaderBackgroundState) {
    guard newState != displayState else { return }
    // Observation callbacks can synchronously call back into this session.
    displayState = newState
    withMutation(keyPath: \.state) {}
  }

  // Tests can wait for a captured request to settle without acquiring its cancellation handle.
  func currentRequestCompletion() -> (@Sendable () async -> Void)? {
    guard let task = request?.task else { return nil }
    return { await task.value }
  }
}
