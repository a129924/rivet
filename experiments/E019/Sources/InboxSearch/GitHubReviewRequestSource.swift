import Foundation
import GitHubIntegration
import RivetHTTPClient
import RivetPRInbox

package struct GitHubReviewRequestSource: ReviewRequestSource {
  package typealias FetchOutcome = Outcome<[ReviewRequestCandidate], PRInboxFailure>

  private static let query = "is:pr is:open user-review-requested:@me"
  private static let pageSize = 100
  private static let pageLimit = 10

  package static let headers = HTTPHeaders([
    "Accept": "application/vnd.github+json",
    "User-Agent": "Rivet-E019",
    "X-GitHub-Api-Version": "2026-03-10",
  ])

  private let rest: any GitHubRestClient
  private let deadline: ContinuousClock.Instant?

  package init(rest: any GitHubRestClient, deadline: ContinuousClock.Instant? = nil) {
    self.rest = rest
    self.deadline = deadline
  }

  package func fetchReviewRequestCandidates() async -> FetchOutcome {
    do {
      return .success(try await loadSearchPages())
    } catch {
      return .failure(.unavailable)
    }
  }

  private func loadSearchPages() async throws -> [ReviewRequestCandidate] {
    var query = URLComponents()
    query.scheme = "https"
    query.host = "api.github.com"
    query.path = "/search/issues"
    query.queryItems = [
      URLQueryItem(name: "q", value: Self.query),
      URLQueryItem(name: "per_page", value: String(Self.pageSize)),
    ]
    guard var url = query.url else { throw PRInboxFailure.unavailable }
    var candidates: [ReviewRequestCandidate] = []
    var expectedTotal: Int?

    for page in 1...Self.pageLimit {
      try checkBudget()
      let response = try await rest.get(url: HTTPURL(url), headers: Self.headers, body: nil)
      try checkBudget()
      guard response.statusCode == 200 else { throw PRInboxFailure.unavailable }

      let payload = try response.json(SearchPage.self, decoder: JSONDecoder())
      guard !payload.incomplete,
        (0...(Self.pageSize * Self.pageLimit)).contains(payload.total),
        payload.items.count <= Self.pageSize,
        expectedTotal == nil || expectedTotal == payload.total
      else { throw PRInboxFailure.unavailable }
      expectedTotal = payload.total

      candidates.append(contentsOf: try payload.items.map { try $0.toCandidate() })
      let next = try Self.nextPage(in: response.headers.link, after: page)
      if let next {
        guard candidates.count < payload.total else { throw PRInboxFailure.unavailable }
        url = next
      } else {
        guard candidates.count == payload.total else { throw PRInboxFailure.unavailable }
        return candidates
      }
    }
    throw PRInboxFailure.unavailable
  }

  private func checkBudget() throws {
    try Task.checkCancellation()
    if let deadline, ContinuousClock.now >= deadline { throw CancellationError() }
  }

  private static func nextPage(in link: String?, after page: Int) throws -> URL? {
    guard let link else { return nil }
    var target: URL?
    for rawLink in link.split(separator: ",", omittingEmptySubsequences: false) {
      let entry = rawLink.trimmingCharacters(in: .whitespaces)
      guard entry.first == "<", let end = entry.firstIndex(of: ">") else {
        throw PRInboxFailure.unavailable
      }
      let parameters = entry[entry.index(after: end)...].split(separator: ";")
      let relations = parameters.compactMap { parameter -> String? in
        let pair = parameter.split(separator: "=", maxSplits: 1)
        guard pair.count == 2, pair[0].trimmingCharacters(in: .whitespaces) == "rel" else {
          return nil
        }
        return pair[1].trimmingCharacters(in: .whitespaces)
      }
      guard relations.count == 1, let relation = relations.first else {
        throw PRInboxFailure.unavailable
      }
      guard relation == "\"next\"" || relation == "next" else { continue }
      let destination = String(entry[entry.index(after: entry.startIndex)..<end])
      guard target == nil, page < pageLimit,
        var parts = URLComponents(string: destination),
        isGitHubAPI(parts), parts.percentEncodedPath == "/search/issues"
      else { throw PRInboxFailure.unavailable }

      // GitHub Links can encode search-query spaces as plus signs.
      let url = parts.url
      parts.percentEncodedQuery = parts.percentEncodedQuery?.replacingOccurrences(
        of: "+", with: "%20")
      let expected = [
        URLQueryItem(name: "q", value: query),
        URLQueryItem(name: "per_page", value: String(pageSize)),
        URLQueryItem(name: "page", value: String(page + 1)),
      ]
      guard let url, let items = parts.queryItems, items.count == expected.count,
        expected.allSatisfy(items.contains)
      else { throw PRInboxFailure.unavailable }
      target = url
    }
    return target
  }

  fileprivate static func isGitHubAPI(_ parts: URLComponents) -> Bool {
    parts.scheme?.lowercased() == "https"
      && parts.host?.lowercased() == "api.github.com"
      && (parts.port == nil || parts.port == 443)
      && parts.user == nil && parts.password == nil && parts.fragment == nil
  }
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
  let repositoryURL: String
  let number: Int
  let title: String
  let state: State
  let pullRequest: PullRequestMarker

  enum CodingKeys: String, CodingKey {
    case repositoryURL = "repository_url"
    case number, title, state
    case pullRequest = "pull_request"
  }

  enum State: String, Decodable, Sendable {
    case open, closed
  }

  func toCandidate() throws -> ReviewRequestCandidate {
    guard number > 0, !title.isEmpty,
      let parts = URLComponents(string: repositoryURL),
      GitHubReviewRequestSource.isGitHubAPI(parts), parts.query == nil
    else { throw PRInboxFailure.unavailable }

    let path = parts.path.split(separator: "/", omittingEmptySubsequences: false)
    guard path.count == 4, path[0].isEmpty, path[1] == "repos",
      Self.isRepositoryComponent(path[2]), Self.isRepositoryComponent(path[3])
    else { throw PRInboxFailure.unavailable }

    return ReviewRequestCandidate(
      item: InboxItem(
        owner: String(path[2]), repository: String(path[3]), number: number, title: title),
      isOpen: state == .open,
      isDirectlyRequestedForCurrentUser: true)
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
