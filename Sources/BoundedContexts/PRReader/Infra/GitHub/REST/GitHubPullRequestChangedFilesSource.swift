import Foundation
import GitHubIntegration
import RivetHTTPClient
import RivetPRReader

package struct GitHubPullRequestChangedFilesSource: Sendable {
  private static let pageSize = 100
  private static let pageLimit = 30
  private static let fileLimit = pageSize * pageLimit

  private let client: any GitHubRestClient

  package init(client: any GitHubRestClient) {
    self.client = client
  }

  package func fetchChangedFiles(
    for id: ReaderPullRequestID
  ) async -> Outcome<[ReaderFile], PRReaderFailure> {
    do {
      let files = try await readFiles(for: id)
      return Task.isCancelled ? .failure(.unavailable) : .success(files)
    } catch {
      return .failure(Task.isCancelled ? .unavailable : error)
    }
  }

  private func readFiles(
    for id: ReaderPullRequestID
  ) async throws(PRReaderFailure) -> [ReaderFile] {
    guard !Task.isCancelled else { throw .unavailable }
    let endpoint = GitHubPullRequestChangedFilesEndpoint(id: id)
    guard var url = try? endpoint.makeURL() else { throw .notReadable }

    var files: [ReaderFile] = []
    var paths: Set<String> = []
    var repositoryID: Int?
    for page in 1...Self.pageLimit {
      let response = try await get(url, isFirstPage: page == 1)
      let (entries, links) = try Self.checkPage(
        response, current: page, accumulatedCount: files.count, id: id)
      if let candidateID = links.next?.repositoryID, repositoryID == nil {
        repositoryID = try await verifiedRepositoryID(for: id, matching: candidateID)
      }
      try links.checkRepositoryID(repositoryID)

      for entry in entries {
        guard let file = entry.file?.readerFile, paths.insert(file.reference.value).inserted
        else { throw .contentNotRepresentable }
        files.append(file)
      }
      guard let next = links.next else { return files }
      guard let nextURL = try? endpoint.makeURL(page: next.page) else { throw .unavailable }
      url = nextURL
    }
    throw .unavailable
  }

  private static func checkPage(
    _ response: HTTPResponse, current: Int, accumulatedCount: Int, id: ReaderPullRequestID
  ) throws(PRReaderFailure) -> ([ChangedFileEntry], ChangedFilesLinks) {
    guard let entries = try? response.json([ChangedFileEntry].self, decoder: JSONDecoder())
    else { throw .contentNotRepresentable }

    guard accumulatedCount + entries.count < fileLimit,
      entries.count <= pageSize, current == 1 || !entries.isEmpty
    else { throw .unavailable }

    let links = try ChangedFilesLinks(header: response.headers.link, id: id)
    try links.checkPage(current: current)
    if links.next != nil {
      guard current < pageLimit, entries.count == pageSize else { throw .unavailable }
    }
    return (entries, links)
  }

  private func get(
    _ url: HTTPURL, isFirstPage: Bool = false
  ) async throws(PRReaderFailure) -> HTTPResponse {
    let response: HTTPResponse
    do {
      try Task.checkCancellation()
      let headers = try GitHubHeadersFactory.standard.make(requirements: [.standardREST])
      response = try await client.get(url: url, headers: headers, body: nil)
      try Task.checkCancellation()
    } catch GitHubHTTPClientError.authenticationRequired {
      throw Task.isCancelled ? .unavailable : .notReadable
    } catch GitHubHTTPClientError.invalidRequest {
      throw isFirstPage && !Task.isCancelled ? .notReadable : .unavailable
    } catch {
      throw .unavailable
    }

    guard response.statusCode != 200 else { return response }
    switch GitHubResponseClassifier().classifyFailure(response) {
    case .unauthorized, .notFound, .forbidden, .unclassifiedForbidden:
      throw .notReadable
    case .rateLimited, .serverError, .unexpectedStatus:
      throw .unavailable
    }
  }

  private func verifiedRepositoryID(
    for id: ReaderPullRequestID, matching candidateID: Int
  ) async throws(PRReaderFailure) -> Int {
    guard let url = try? GitHubPullRequestDetailEndpoint(id: id).makeURL()
    else { throw .unavailable }

    let response = try await get(url)
    guard
      let repositoryID = GitHubPullRequestRepositoryIdentity.verifiedRepositoryID(
        in: response, for: id, matching: candidateID)
    else { throw .unavailable }
    return repositoryID
  }
}

private struct ChangedFileEntry: Decodable, Sendable {
  let file: ChangedFile?

  init(from decoder: any Decoder) {
    // Count each array element even when its value cannot be projected.
    file = try? ChangedFile(from: decoder)
  }
}

private struct ChangedFile: Decodable, Sendable {
  let filename: String
  let status: Status
  let additions: Int
  let deletions: Int
  let previousFilename: String?
  let patch: String?

  enum CodingKeys: String, CodingKey {
    case filename, status, additions, deletions, patch
    case previousFilename = "previous_filename"
  }

  enum Status: String, Decodable, Sendable {
    case added, removed, modified, renamed, copied

    var readerChange: FileChange {
      switch self {
      case .added: .added
      case .removed: .removed
      case .modified: .modified
      case .renamed: .renamed
      case .copied: .copied
      }
    }
  }

  var readerFile: ReaderFile? {
    guard !filename.isEmpty, additions >= 0, deletions >= 0 else { return nil }
    return ReaderFile(
      reference: ReaderFileReference(value: filename),
      path: filename,
      previousPath: previousFilename,
      change: status.readerChange,
      additions: additions,
      deletions: deletions,
      patch: patch)
  }
}

private struct ChangedFilesLinks {
  let next: PageLink?
  let last: PageLink?

  init(header: String?, id: ReaderPullRequestID) throws(PRReaderFailure) {
    guard let header else {
      next = nil
      last = nil
      return
    }

    var nextLink: PageLink?
    var lastLink: PageLink?
    var cursor = header[...]
    while true {
      cursor = cursor.drop(while: Self.isHeaderWhitespace)
      guard let target = cursor.prefixMatch(of: /<([^<>\s]+)>/) else { throw .unavailable }
      cursor = cursor[target.range.upperBound...]
      let relations = try Self.readRelations(from: &cursor)
      if relations.contains("next") || relations.contains("last") {
        let link = try PageLink(target: target.output.1, id: id)
        if relations.contains("next") {
          guard nextLink == nil else { throw .unavailable }
          nextLink = link
        }
        if relations.contains("last") {
          guard lastLink == nil else { throw .unavailable }
          lastLink = link
        }
      }

      cursor = cursor.drop(while: Self.isHeaderWhitespace)
      if cursor.isEmpty { break }
      guard cursor.removeFirst() == "," else { throw .unavailable }
    }
    next = nextLink
    last = lastLink
  }

  func checkPage(current: Int) throws(PRReaderFailure) {
    if let next, next.page != current + 1 { throw .unavailable }
    if let last, let next {
      guard last.page >= next.page else { throw .unavailable }
    } else if let last, last.page != current {
      throw .unavailable
    }
  }

  func checkRepositoryID(_ verifiedID: Int?) throws(PRReaderFailure) {
    guard let verifiedID else { return }
    for id in [next?.repositoryID, last?.repositoryID].compactMap({ $0 }) {
      guard id == verifiedID else { throw .unavailable }
    }
  }

  private static func readRelations(
    from cursor: inout Substring
  ) throws(PRReaderFailure) -> Set<String> {
    var relations: Set<String>?
    let parameter =
      #/[ \t]*;[ \t]*([!#$%&'*+.^_`|~0-9A-Za-z-]+)[ \t]*=[ \t]*("(?:[^"\\\r\n]|\\[^\r\n])*"|[!#$%&'*+.^_`|~0-9A-Za-z-]+)/#
    while let match = cursor.prefixMatch(of: parameter) {
      cursor = cursor[match.range.upperBound...]
      let name = match.output.1.lowercased()
      guard name != "anchor" else { throw .unavailable }
      guard name == "rel" else { continue }
      guard relations == nil else { throw .unavailable }
      let value = match.output.2
      let relationValue =
        value.first == "\""
        ? value.dropFirst().dropLast().replacingOccurrences(
          of: #"\\(.)"#, with: "$1", options: .regularExpression)
        : String(value)
      let tokens = relationValue.split(whereSeparator: isHeaderWhitespace)
      guard !tokens.isEmpty,
        tokens.allSatisfy({
          $0.wholeMatch(of: /[A-Za-z][A-Za-z0-9.-]*/) != nil
            || URLComponents(string: String($0))?.scheme != nil
        })
      else { throw .unavailable }
      let names = Set(tokens.map { $0.lowercased() })
      guard names.count == tokens.count else { throw .unavailable }
      relations = names
    }
    guard let relations else { throw .unavailable }
    return relations
  }

  private static func isHeaderWhitespace(_ character: Character) -> Bool {
    character == " " || character == "\t"
  }

  struct PageLink {
    let page: Int
    let repositoryID: Int?

    init(target: Substring, id: ReaderPullRequestID) throws(PRReaderFailure) {
      guard let components = URLComponents(string: String(target)),
        GitHubRESTDestination.isAllowed(components),
        let query = components.queryItems, query.count == 2,
        let pageValue = query.first(where: { $0.name == "page" })?.value,
        let page = Self.positiveInteger(pageValue),
        query.contains(URLQueryItem(name: "per_page", value: "100"))
      else { throw .unavailable }

      let path = components.percentEncodedPath.split(
        separator: "/", omittingEmptySubsequences: false)
      let suffix = ["pulls", String(id.number), "files"]
      guard path.first == "", path.suffix(3).map({ String($0) }) == suffix
      else { throw .unavailable }

      if path.count == 7 && path[1] == "repos" {
        guard Self.matches(path[2], name: id.owner), Self.matches(path[3], name: id.repository)
        else { throw .unavailable }
        repositoryID = nil
      } else if path.count == 6 && path[1] == "repositories" {
        guard let numericID = Self.positiveInteger(path[2]) else { throw .unavailable }
        repositoryID = numericID
      } else {
        throw .unavailable
      }
      self.page = page
    }

    private static func matches(_ candidate: Substring, name: String) -> Bool {
      candidate.utf8.allSatisfy { $0 < 128 } && candidate.lowercased() == name.lowercased()
    }

    private static func positiveInteger(_ value: some StringProtocol) -> Int? {
      guard value.utf8.allSatisfy({ (48...57).contains($0) }), let number = Int(value), number > 0
      else { return nil }
      return number
    }
  }
}
