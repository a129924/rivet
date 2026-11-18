import Foundation
import GitHubIntegration
import RivetHTTPClient
import RivetPRInbox

public struct GitHubSelfReviewSource: SelfReviewSource {
  private static let pageSize = 100
  private static let pageLimit = 10
  private static let headers = HTTPHeaders([
    "Accept": "application/vnd.github+json",
    "User-Agent": "Rivet",
    "X-GitHub-Api-Version": "2026-03-10",
  ])

  private let rest: any GitHubRestClient

  public init(rest: any GitHubRestClient) {
    self.rest = rest
  }

  public func fetchSelfReviewCandidates() async -> Outcome<[SelfReviewCandidate], PRInboxFailure> {
    do {
      guard let viewerURL = URL(string: "https://api.github.com/user") else {
        return .failure(.unavailable)
      }
      let response = try await get(viewerURL)
      let viewer = try response.json(Viewer.self, decoder: JSONDecoder())
      guard Self.isSearchableLogin(viewer.login) else { return .failure(.unavailable) }
      return .success(try await search(viewerLogin: viewer.login))
    } catch {
      return .failure(.unavailable)
    }
  }

  private func search(viewerLogin: String) async throws -> [SelfReviewCandidate] {
    let query = "is:pr is:open author:\(viewerLogin)"
    var url = try Self.searchURL(query: query)
    var candidates: [SelfReviewCandidate] = []
    var total: Int?

    for page in 1...Self.pageLimit {
      let response = try await get(url)
      let payload = try response.json(SearchPage.self, decoder: JSONDecoder())
      guard !payload.incomplete,
        (0...(Self.pageLimit * Self.pageSize)).contains(payload.total),
        payload.items.count <= Self.pageSize,
        total == nil || total == payload.total
      else { throw PRInboxFailure.unavailable }

      total = payload.total
      candidates += try payload.items.map { try $0.candidate(for: viewerLogin) }
      guard let next = try Self.nextURL(in: response.headers.link, query: query, page: page) else {
        guard candidates.count == payload.total else { throw PRInboxFailure.unavailable }
        return candidates
      }
      guard candidates.count < payload.total else { throw PRInboxFailure.unavailable }
      url = next
    }
    throw PRInboxFailure.unavailable
  }

  private func get(_ url: URL) async throws -> HTTPResponse {
    try Task.checkCancellation()
    let response = try await rest.get(url: HTTPURL(url), headers: Self.headers, body: nil)
    try Task.checkCancellation()
    guard response.statusCode == 200 else { throw PRInboxFailure.unavailable }
    return response
  }

  private static func isSearchableLogin(_ login: String) -> Bool {
    !login.isEmpty
      && login.utf8.allSatisfy { byte in
        (48...57).contains(byte) || (65...90).contains(byte) || (97...122).contains(byte)
          || byte == 45
      }
  }

  private static func searchURL(query: String) throws -> URL {
    var components = URLComponents()
    components.scheme = "https"
    components.host = "api.github.com"
    components.path = "/search/issues"
    components.queryItems = [
      URLQueryItem(name: "q", value: query),
      URLQueryItem(name: "per_page", value: String(pageSize)),
    ]
    guard let url = components.url else { throw PRInboxFailure.unavailable }
    return url
  }

  private static func nextURL(in link: String?, query: String, page: Int) throws -> URL? {
    guard let link else { return nil }
    var next: URL?
    for part in link.split(separator: ",", omittingEmptySubsequences: false) {
      let entry = part.trimmingCharacters(in: .whitespaces)
      guard entry.first == "<", let end = entry.firstIndex(of: ">") else {
        throw PRInboxFailure.unavailable
      }
      let relation = try linkRelation(entry[entry.index(after: end)...])
      guard relation == "next" else { continue }

      let destination = String(entry[entry.index(after: entry.startIndex)..<end])
      guard next == nil, page < pageLimit,
        var components = URLComponents(string: destination),
        isGitHubAPI(components), components.percentEncodedPath == "/search/issues",
        let url = components.url
      else { throw PRInboxFailure.unavailable }

      // GitHub encodes spaces in some paging links as plus signs.
      components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(
        of: "+", with: "%20")
      let expected = [
        URLQueryItem(name: "q", value: query),
        URLQueryItem(name: "per_page", value: String(pageSize)),
        URLQueryItem(name: "page", value: String(page + 1)),
      ]
      guard let items = components.queryItems, items.count == expected.count,
        expected.allSatisfy(items.contains)
      else { throw PRInboxFailure.unavailable }
      next = url
    }
    return next
  }

  private static func linkRelation(_ parameters: Substring) throws -> String {
    let relations = parameters.split(separator: ";").compactMap { parameter -> String? in
      let pair = parameter.split(separator: "=", maxSplits: 1)
      guard pair.count == 2, pair[0].trimmingCharacters(in: .whitespaces) == "rel" else {
        return nil
      }
      let value = pair[1].trimmingCharacters(in: .whitespaces)
      return value.hasPrefix("\"") && value.hasSuffix("\"")
        ? String(value.dropFirst().dropLast()) : value
    }
    guard relations.count == 1, let relation = relations.first, !relation.isEmpty else {
      throw PRInboxFailure.unavailable
    }
    return relation
  }
}

private func isGitHubAPI(_ components: URLComponents) -> Bool {
  components.scheme?.lowercased() == "https"
    && components.host?.lowercased() == "api.github.com"
    && (components.port == nil || components.port == 443)
    && components.user == nil && components.password == nil && components.fragment == nil
}

private struct Viewer: Decodable, Sendable {
  let login: String
}

private struct SearchPage: Decodable, Sendable {
  let total: Int
  let incomplete: Bool
  let items: [SearchItem]

  enum CodingKeys: String, CodingKey {
    case total = "total_count"
    case incomplete = "incomplete_results"
    case items
  }
}

private struct SearchItem: Decodable, Sendable {
  enum State: String, Decodable, Sendable {
    case open, closed
  }

  let repositoryURL: String
  let number: Int
  let title: String
  let state: State
  let user: Viewer?
  let pullRequest: PullRequestMarker

  enum CodingKeys: String, CodingKey {
    case repositoryURL = "repository_url"
    case number, title, state, user
    case pullRequest = "pull_request"
  }

  func candidate(for viewerLogin: String) throws -> SelfReviewCandidate {
    guard number > 0, !title.isEmpty,
      let repository = URLComponents(string: repositoryURL),
      isGitHubAPI(repository), repository.query == nil
    else { throw PRInboxFailure.unavailable }

    let path = repository.path.split(separator: "/", omittingEmptySubsequences: false)
    guard path.count == 4, path[0].isEmpty, path[1] == "repos",
      Self.isRepositoryComponent(path[2]), Self.isRepositoryComponent(path[3])
    else { throw PRInboxFailure.unavailable }

    return SelfReviewCandidate(
      item: InboxItem(
        owner: String(path[2]), repository: String(path[3]), number: number, title: title),
      isOpen: state == .open,
      isAuthoredByCurrentUser: user?.login.caseInsensitiveCompare(viewerLogin) == .orderedSame)
  }

  private static func isRepositoryComponent(_ value: Substring) -> Bool {
    !value.isEmpty && value != "." && value != ".."
      && value.utf8.allSatisfy { byte in
        (48...57).contains(byte) || (65...90).contains(byte) || (97...122).contains(byte)
          || byte == 45 || byte == 46 || byte == 95
      }
  }
}

private struct PullRequestMarker: Decodable, Sendable {
  private enum CodingKeys: String, CodingKey { case url }

  init(from decoder: any Decoder) throws {
    _ = try decoder.container(keyedBy: CodingKeys.self)
  }
}
