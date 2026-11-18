import Foundation
import GitHubIntegration
import RivetHTTPClient

struct GitHubAccount: Decodable, Equatable, Sendable {
  let id: Int64
  let login: String
}

enum GitHubAccountProbeError: Error { case invalidResponse }

enum GitHubAccountProbe {
  static func load(using client: any GitHubRestClient) async throws -> GitHubAccount {
    let response = try await client.get(
      url: HTTPURL(URL(string: "https://api.github.com/user")!),
      headers: [
        .accept: "application/vnd.github+json", .userAgent: "GitHubConnectionVerification",
      ], body: nil)
    guard response.statusCode == 200,
      let account = try? JSONDecoder().decode(GitHubAccount.self, from: response.body),
      account.id > 0, !account.login.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    else { throw GitHubAccountProbeError.invalidResponse }
    return account
  }
}
