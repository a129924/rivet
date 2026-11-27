import Foundation
import GitHubIntegration
import RivetHTTPClient
import RivetPRReader

package struct GitHubPullRequestBackgroundSource: PRBackgroundSource {
  private static var headers: HTTPHeaders {
    get throws {
      try GitHubHeadersFactory.standard.make(requirements: [.standardREST])
    }
  }

  private let client: any GitHubRestClient

  package init(client: any GitHubRestClient) {
    self.client = client
  }

  package func fetchBackground(
    for id: ReaderPullRequestID
  ) async -> Outcome<ReaderBackground, PRReaderFailure> {
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
      response = try await client.get(url: url, headers: Self.headers, body: nil)
      try Task.checkCancellation()
    } catch GitHubHTTPClientError.authenticationRequired, GitHubHTTPClientError.invalidRequest {
      return .failure(Task.isCancelled ? .unavailable : .notReadable)
    } catch {
      return .failure(.unavailable)
    }

    guard response.statusCode == 200 else { return .failure(Self.failure(for: response)) }
    do {
      let detail = try response.json(PullRequestDetail.self, decoder: JSONDecoder())
      return .success(
        ReaderBackground(title: detail.title, body: detail.body, author: detail.user?.login))
    } catch {
      return .failure(.contentNotRepresentable)
    }
  }

  private static func failure(for response: HTTPResponse) -> PRReaderFailure {
    switch GitHubResponseClassifier().classifyFailure(response) {
    case .unauthorized, .notFound, .forbidden, .unclassifiedForbidden:
      return .notReadable
    case .unprocessableContent, .rateLimited, .serverError, .unexpectedStatus:
      return .unavailable
    }
  }
}

private struct PullRequestDetail: Decodable, Sendable {
  struct User: Decodable, Sendable {
    let login: String
  }

  let title: String
  let body: String?
  let user: User?
}
