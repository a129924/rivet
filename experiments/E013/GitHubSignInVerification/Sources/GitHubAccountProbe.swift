import Foundation
import GitHubIntegration
import RivetHTTPClient

struct GitHubAccountIdentity: Decodable, Sendable, Equatable {
  let login: String
  let id: Int
}

enum GitHubAccountProbeError: Error {
  case http(Int)
  case invalidResponse
}

struct GitHubAccountProbe {
  static func read(using scope: GitHubClientScope) async throws -> GitHubAccountIdentity {
    try await read(client: scope.rest)
  }

  static func read(client: any GitHubRestClient) async throws -> GitHubAccountIdentity {
    let response = try await client.get(
      url: HTTPURL(URL(string: "https://api.github.com/user")!),
      headers: [.accept: "application/vnd.github+json", .userAgent: "GitHubSignInVerification"],
      body: nil)
    guard response.statusCode == 200 else {
      throw GitHubAccountProbeError.http(response.statusCode)
    }
    guard let identity = try? JSONDecoder().decode(GitHubAccountIdentity.self, from: response.body),
      identity.id > 0,
      !identity.login.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty
    else { throw GitHubAccountProbeError.invalidResponse }
    return identity
  }
}
