import Foundation
import RivetHTTPClient

struct GitHubLoginAccountProbe: Sendable {
  let client: HTTPClient
  private let headersFactory: GitHubHeadersFactory

  init(
    client: HTTPClient = GitHubHTTPClient.makeHTTPClient(),
    headersFactory: GitHubHeadersFactory = .standard
  ) {
    self.client = client
    self.headersFactory = headersFactory
  }

  func validate(token: String) async throws {
    try Task.checkCancellation()
    let endpoint = GitHubAuthenticatedUserEndpoint.shared
    let request = HTTPRequest(
      url: try endpoint.makeURL(), method: endpoint.method,
      headers: try headersFactory.make(requirements: [.loginRuntimeREST]))
    let authorized = try BearerAuth(token: token).applying(to: request)
    let response = try await client.execute(authorized)
    try Task.checkCancellation()
    guard response.statusCode == 200,
      let identity = try? JSONDecoder().decode(Identity.self, from: response.body),
      identity.id > 0,
      !identity.login.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    else { throw Failure.invalidResponse }
  }

  private struct Identity: Decodable {
    let id: Int
    let login: String
  }

  private enum Failure: Error { case invalidResponse }
}
