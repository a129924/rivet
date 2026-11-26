import Foundation
import RivetHTTPClient

package struct GitHubUnreadNotificationsSource: Sendable {
  private let client: HTTPClient

  /// The composition root supplies a client whose transport returns the original redirect
  /// response without following it. Use `GitHubRESTTransport.makeClient()` in production.
  package init(client: HTTPClient) {
    self.client = client
  }

  package func list(using token: PersonalAccessToken?) async -> GitHubUnreadNotificationsOutcome {
    do {
      try Task.checkCancellation()
      guard let token, let bearer = try? BearerAuth(token: token.rawValue) else {
        throw GitHubUnreadNotificationsFailure.accessDenied
      }
      let threads = try await readAll(using: bearer, token: token)
      try Task.checkCancellation()
      return .success(threads)
    } catch {
      if Task.isCancelled || error is CancellationError { return .cancelled }
      return .failure(error as? GitHubUnreadNotificationsFailure ?? .unavailable)
    }
  }

  private func readAll(
    using bearer: BearerAuth, token: PersonalAccessToken
  ) async throws -> [GitHubNotificationThread] {
    let endpoint = GitHubUnreadNotificationsEndpoint()
    let headers = try GitHubHeadersFactory.standard.make(requirements: [.standardREST])
    var threads: [GitHubNotificationThread] = []
    var page = 1

    while true {
      try Task.checkCancellation()
      let unavailable: GitHubUnreadNotificationsFailure =
        page == 1 ? .unavailable : .incompletePagination
      guard let url = try? endpoint.makeURL(page: page) else { throw unavailable }
      let request = bearer.applying(
        to: HTTPRequest(url: url, method: endpoint.method, headers: headers))
      let response = try await send(request, failure: unavailable)
      guard response.statusCode == endpoint.successStatus else {
        switch GitHubResponseClassifier().classifyFailure(response) {
        case .unauthorized, .forbidden, .unclassifiedForbidden:
          throw GitHubUnreadNotificationsFailure.accessDenied
        default:
          throw unavailable
        }
      }

      let pageThreads = try GitHubNotificationThread.decodePage(response, excluding: token)
      threads.append(contentsOf: pageThreads)
      guard
        let next = try GitHubUnreadNotificationsPageLinks.nextPage(
          link: response.headers.link, after: page)
      else { return threads }
      page = next
    }
  }

  private func send(
    _ request: HTTPRequest, failure: GitHubUnreadNotificationsFailure
  ) async throws -> HTTPResponse {
    let response: HTTPResponse
    do {
      response = try await client.execute(request)
    } catch {
      if case .cancelled = error { throw CancellationError() }
      throw failure
    }
    try Task.checkCancellation()
    return response
  }
}
