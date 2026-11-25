import Foundation
import RivetHTTPClient
import RivetPRReader

enum GitHubPullRequestRepositoryIdentity {
  static func verifiedRepositoryID(
    in response: HTTPResponse, for id: ReaderPullRequestID, matching candidateID: Int
  ) -> Int? {
    guard candidateID > 0,
      let detail = try? response.json(PullRequestIdentity.self, decoder: JSONDecoder()),
      detail.number == id.number, detail.base.repo.id == candidateID,
      detail.base.repo.fullName.utf8.allSatisfy({ $0 < 128 }),
      detail.base.repo.fullName.lowercased() == "\(id.owner)/\(id.repository)".lowercased()
    else { return nil }
    return detail.base.repo.id
  }
}

private struct PullRequestIdentity: Decodable, Sendable {
  let number: Int
  let base: Base

  struct Base: Decodable, Sendable {
    let repo: Repository
  }
}

private struct Repository: Decodable, Sendable {
  let id: Int
  let fullName: String

  enum CodingKeys: String, CodingKey {
    case id
    case fullName = "full_name"
  }
}
