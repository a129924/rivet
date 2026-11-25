import Foundation
import GitHubIntegration
import RivetHTTPClient

package struct GitHubRepositoryPullRequestSummary: Sendable, Equatable {
  package let number: Int
  package let title: String
}

package enum GitHubRepositoryOpenPullRequestsFailure: Error, Sendable, Equatable {
  case invalidRepository
  case requestFailed
  case invalidResponse
  case invalidPagination
  case cancelled
}

private typealias QueryFailure = GitHubRepositoryOpenPullRequestsFailure

package struct GitHubRepositoryOpenPullRequestsQuery: Sendable {
  private let rest: any GitHubRestClient

  package init(rest: any GitHubRestClient) {
    self.rest = rest
  }

  package func fetch(
    owner: String, repository: String
  ) async -> Result<[GitHubRepositoryPullRequestSummary], GitHubRepositoryOpenPullRequestsFailure> {
    do {
      let summaries = try await fetchAll(owner: owner, repository: repository)
      try Task.checkCancellation()
      return .success(summaries)
    } catch {
      if error is CancellationError || Task.isCancelled { return .failure(.cancelled) }
      return .failure(error as? GitHubRepositoryOpenPullRequestsFailure ?? .requestFailed)
    }
  }

  private func fetchAll(
    owner: String, repository: String
  ) async throws -> [GitHubRepositoryPullRequestSummary] {
    try Task.checkCancellation()
    let endpoint = GitHubRepositoryOpenPullRequestsEndpoint(owner: owner, repository: repository)
    guard var url = try? endpoint.makeURL() else {
      throw GitHubRepositoryOpenPullRequestsFailure.invalidRepository
    }
    let headers = try GitHubHeadersFactory.standard.make(requirements: [.standardREST])
    let decoder = JSONDecoder()
    var identity = RepositoryIdentity(owner: owner, repository: repository)
    var summaries: [GitHubRepositoryPullRequestSummary] = []
    var page = 1

    while true {
      let response = try await get(url: url, headers: headers)
      guard let items = try? response.json([PullRequest].self, decoder: decoder) else {
        throw GitHubRepositoryOpenPullRequestsFailure.invalidResponse
      }
      for item in items {
        guard item.number > 0, item.state == "open" else {
          throw GitHubRepositoryOpenPullRequestsFailure.invalidResponse
        }
        try identity.observe(item.base?.repo)
        summaries.append(GitHubRepositoryPullRequestSummary(number: item.number, title: item.title))
      }
      guard
        let nextPage = try nextPage(
          link: response.headers.link, page: page, identity: identity)
      else {
        return summaries
      }
      guard let nextURL = try? endpoint.makeURL(page: nextPage) else {
        throw GitHubRepositoryOpenPullRequestsFailure.invalidPagination
      }
      page = nextPage
      url = nextURL
    }
  }

  private func get(url: HTTPURL, headers: HTTPHeaders) async throws -> HTTPResponse {
    try Task.checkCancellation()
    let response: HTTPResponse
    do {
      response = try await rest.get(url: url, headers: headers, body: nil)
    } catch is CancellationError {
      throw CancellationError()
    } catch {
      throw GitHubRepositoryOpenPullRequestsFailure.requestFailed
    }
    try Task.checkCancellation()
    guard response.statusCode == 200 else {
      throw GitHubRepositoryOpenPullRequestsFailure.requestFailed
    }
    return response
  }

  private func nextPage(link: String?, page: Int, identity: RepositoryIdentity) throws -> Int? {
    guard let link else { return nil }
    var parser = LinkHeader(link)
    guard let target = try parser.nextURL() else { return nil }
    guard
      let components = URLComponents(url: target, resolvingAgainstBaseURL: false),
      GitHubRESTDestination.isAllowed(components),
      identity.matches(path: components.percentEncodedPath)
    else { throw QueryFailure.invalidPagination }

    let (expected, overflow) = page.addingReportingOverflow(1)
    guard !overflow else { throw QueryFailure.invalidPagination }
    let parameters = try PaginationParameters(components.queryItems)
    guard parameters.page == expected else { throw QueryFailure.invalidPagination }
    return expected
  }
}

private struct PullRequest: Decodable, Sendable {
  let number: Int
  let title: String
  let state: String
  let base: Base?

  struct Base: Decodable, Sendable {
    let repo: RepositoryEvidence?
  }
}

private struct RepositoryEvidence: Decodable, Sendable {
  let fullName: String?
  let id: Int?

  private enum CodingKeys: String, CodingKey {
    case fullName = "full_name"
    case id
  }
}

private struct RepositoryIdentity {
  let owner: String
  let repository: String
  private var observedID: Int?
  private var provenID: Int?

  init(owner: String, repository: String) {
    self.owner = owner
    self.repository = repository
  }

  mutating func observe(_ evidence: RepositoryEvidence?) throws(QueryFailure) {
    guard let evidence else { return }
    if let name = evidence.fullName, !asciiCaseEqual(name, "\(owner)/\(repository)") {
      throw .invalidResponse
    }
    guard let id = evidence.id else { return }
    guard id > 0, observedID == nil || observedID == id else { throw .invalidResponse }
    observedID = id
    if evidence.fullName != nil { provenID = id }
  }

  func matches(path: String) -> Bool {
    guard path.first == "/", !path.contains("%") else { return false }
    let segments = path.dropFirst().split(separator: "/", omittingEmptySubsequences: false)
    switch segments.count {
    case 4:
      return segments[0] == "repos" && segments[3] == "pulls"
        && asciiCaseEqual(segments[1], owner) && asciiCaseEqual(segments[2], repository)
    case 3:
      guard let provenID, segments[0] == "repositories", segments[2] == "pulls" else {
        return false
      }
      return positiveInteger(segments[1]) == provenID
    default:
      return false
    }
  }
}

private struct PaginationParameters {
  let page: Int

  init(_ items: [URLQueryItem]?) throws(QueryFailure) {
    var values: [String: String] = [:]
    for item in items ?? [] {
      guard let value = item.value, values.updateValue(value, forKey: item.name) == nil else {
        throw .invalidPagination
      }
    }
    let state = values.removeValue(forKey: "state")
    guard
      state == nil || state == "open",
      values.count == 2, values["per_page"] == "100",
      let rawPage = values["page"], let page = positiveInteger(rawPage)
    else { throw .invalidPagination }
    self.page = page
  }
}

private func positiveInteger(_ value: some StringProtocol) -> Int? {
  guard value.utf8.allSatisfy({ (48...57).contains($0) }),
    let integer = Int(value), integer > 0
  else { return nil }
  return integer
}

private func asciiCaseEqual(_ left: some StringProtocol, _ right: some StringProtocol) -> Bool {
  left.utf8.elementsEqual(right.utf8) { lhs, rhs in
    let lowerLeft = (65...90).contains(lhs) ? lhs + 32 : lhs
    let lowerRight = (65...90).contains(rhs) ? rhs + 32 : rhs
    return lowerLeft == lowerRight
  }
}

private struct LinkHeader {
  private var remaining: Substring.UTF8View

  init(_ value: String) {
    remaining = value[...].utf8
  }

  mutating func nextURL() throws(QueryFailure) -> URL? {
    var next: URL?
    while true {
      skipWhitespace()
      if let target = try readLink() {
        guard next == nil else { throw .invalidPagination }
        next = target
      }
      skipWhitespace()
      if remaining.isEmpty { return next }
      guard consume(",") else { throw .invalidPagination }
    }
  }

  private mutating func readLink() throws(QueryFailure) -> URL? {
    let target = try readTarget()
    var hasNext: Bool?
    var hasAnchor = false

    skipWhitespace()
    while consume(";") {
      let (name, value) = try readParameter()
      switch name {
      case "rel":
        guard hasNext == nil, let value else { throw .invalidPagination }
        hasNext = try containsNext(value)
      case "anchor":
        hasAnchor = true
      default:
        break
      }
      skipWhitespace()
    }
    guard let hasNext else { throw .invalidPagination }
    if !hasNext { return nil }
    guard !hasAnchor else { throw .invalidPagination }
    return target
  }

  private mutating func readTarget() throws(QueryFailure) -> URL {
    guard consume("<") else { throw .invalidPagination }
    let reference = try take { $0 != UInt8(ascii: ">") }
    guard consume(">"), let url = URL(string: reference, encodingInvalidCharacters: false) else {
      throw .invalidPagination
    }
    return url
  }

  private mutating func readParameter() throws(QueryFailure) -> (name: String, value: String?) {
    skipWhitespace()
    let name = try take(while: Self.isTokenByte)
    guard !name.isEmpty else { throw .invalidPagination }
    skipWhitespace()
    guard consume("=") else { return (name.lowercased(), nil) }
    skipWhitespace()
    if consume("\"") { return (name.lowercased(), try readQuotedValue()) }
    let value = try take(while: Self.isTokenByte)
    guard !value.isEmpty else { throw .invalidPagination }
    return (name.lowercased(), value)
  }

  private mutating func readQuotedValue() throws(QueryFailure) -> String {
    var bytes: [UInt8] = []
    while !consume("\"") {
      _ = consume("\\")
      guard let byte = remaining.popFirst(), byte == 9 || byte >= 32 && byte != 127 else {
        throw .invalidPagination
      }
      bytes.append(byte)
    }
    guard let value = String(bytes: bytes, encoding: .utf8) else { throw .invalidPagination }
    return value
  }

  private func containsNext(_ value: String) throws(QueryFailure) -> Bool {
    let relations = value.split(separator: " ")
    guard !relations.isEmpty, value.first != " ", value.last != " " else {
      throw .invalidPagination
    }
    var hasNext = false
    for relation in relations {
      guard Self.isRelation(relation) else { throw .invalidPagination }
      if asciiCaseEqual(relation, "next") {
        guard !hasNext else { throw .invalidPagination }
        hasNext = true
      }
    }
    return hasNext
  }

  private static func isRelation(_ value: Substring) -> Bool {
    guard let first = value.utf8.first, isLetter(first) else { return false }
    let registered = value.utf8.allSatisfy {
      isLetter($0) || (48...57).contains($0) || $0 == 45 || $0 == 46
    }
    return registered || URL(string: String(value), encodingInvalidCharacters: false)?.scheme != nil
  }

  private static func isLetter(_ byte: UInt8) -> Bool {
    (65...90).contains(byte) || (97...122).contains(byte)
  }

  private static func isTokenByte(_ byte: UInt8) -> Bool {
    isLetter(byte) || (48...57).contains(byte) || "!#$%&'*+-.^_`|~".utf8.contains(byte)
  }

  private mutating func skipWhitespace() {
    remaining = remaining.drop(while: { $0 == 32 || $0 == 9 })
  }

  private mutating func consume(_ character: Unicode.Scalar) -> Bool {
    guard remaining.first == UInt8(ascii: character) else { return false }
    remaining.removeFirst()
    return true
  }

  private mutating func take(while includes: (UInt8) -> Bool) throws(QueryFailure) -> String {
    let run = remaining.prefix(while: includes)
    remaining = remaining.dropFirst(run.count)
    guard let value = String(bytes: run, encoding: .utf8) else { throw .invalidPagination }
    return value
  }
}
