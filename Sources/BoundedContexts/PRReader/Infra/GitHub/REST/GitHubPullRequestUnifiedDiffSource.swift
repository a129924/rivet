import Foundation
import GitHubIntegration
import RivetHTTPClient
import RivetPRReader

package struct GitHubPullRequestUnifiedDiffSource: Sendable {
  private let client: any GitHubRestClient

  package init(client: any GitHubRestClient) {
    self.client = client
  }

  package func fetchUnifiedDiff(
    for id: ReaderPullRequestID
  ) async -> Outcome<Data, PRReaderFailure> {
    let url: HTTPURL
    do {
      try Task.checkCancellation()
      url = try GitHubPullRequestDetailEndpoint(id: id).makeURL()
    } catch is CancellationError {
      return .failure(.unavailable)
    } catch {
      return .failure(.notReadable)
    }

    let response: HTTPResponse
    do {
      let headers = try GitHubHeadersFactory.standard.make(
        requirements: [.pullRequestUnifiedDiffREST])
      response = try await client.get(url: url, headers: headers, body: nil)
      try Task.checkCancellation()
    } catch GitHubHTTPClientError.authenticationRequired, GitHubHTTPClientError.invalidRequest {
      return .failure(Task.isCancelled ? .unavailable : .notReadable)
    } catch {
      return .failure(.unavailable)
    }

    guard response.statusCode == 200 else {
      switch GitHubResponseClassifier().classifyFailure(response) {
      case .unauthorized, .notFound, .forbidden, .unclassifiedForbidden:
        return .failure(.notReadable)
      case .unprocessableContent, .rateLimited, .serverError, .unexpectedStatus:
        return .failure(.unavailable)
      }
    }
    return .success(response.body)
  }
}
