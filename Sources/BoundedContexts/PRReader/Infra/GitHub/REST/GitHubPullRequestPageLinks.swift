import Foundation
import GitHubIntegration
import RivetPRReader

struct GitHubPullRequestPageLinks {
  enum Route {
    case conversationComments
    case reviews

    fileprivate func pathSuffix(for number: Int) -> [String] {
      switch self {
      case .conversationComments: ["issues", String(number), "comments"]
      case .reviews: ["pulls", String(number), "reviews"]
      }
    }
  }

  let next: PageLink?
  let last: PageLink?

  init(header: String?, id: ReaderPullRequestID, route: Route) throws(PRReaderFailure) {
    guard let header else {
      next = nil
      last = nil
      return
    }

    var pageLinks: [String: PageLink] = [:]
    var cursor = header[...]
    while true {
      cursor = cursor.drop(while: Self.isHeaderWhitespace)
      guard let target = cursor.prefixMatch(of: /<([^<>\s]+)>/) else { throw .unavailable }
      cursor = cursor[target.range.upperBound...]
      let (relations, hasAnchor) = try Self.readParameters(from: &cursor)
      let paginationRelations = relations.intersection(["next", "last"])
      if !paginationRelations.isEmpty {
        guard !hasAnchor else { throw .unavailable }
        let link = try PageLink(target: target.output.1, id: id, route: route)
        for relation in paginationRelations {
          guard pageLinks.updateValue(link, forKey: relation) == nil else { throw .unavailable }
        }
      }

      cursor = cursor.drop(while: Self.isHeaderWhitespace)
      if cursor.isEmpty { break }
      guard cursor.removeFirst() == "," else { throw .unavailable }
    }
    next = pageLinks["next"]
    last = pageLinks["last"]
  }

  func checkPage(current: Int) throws(PRReaderFailure) {
    if let next {
      guard current < Int.max, next.page == current + 1 else { throw .unavailable }
    }
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

  private static func readParameters(
    from cursor: inout Substring
  ) throws(PRReaderFailure) -> (Set<String>, Bool) {
    var relations: Set<String>?
    var hasAnchor = false
    let parameter =
      #/[ \t]*;[ \t]*([!#$%&'*+.^_`|~0-9A-Za-z-]+)[ \t]*=[ \t]*("(?:[^"\\\r\n]|\\[^\r\n])*"|[!#$%&'*+.^_`|~0-9A-Za-z-]+)/#
    while let match = cursor.prefixMatch(of: parameter) {
      cursor = cursor[match.range.upperBound...]
      let name = match.output.1.lowercased()
      if name == "anchor" { hasAnchor = true }
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
    return (relations, hasAnchor)
  }

  private static func isHeaderWhitespace(_ character: Character) -> Bool {
    character == " " || character == "\t"
  }

  struct PageLink {
    let page: Int
    let repositoryID: Int?

    init(target: Substring, id: ReaderPullRequestID, route: Route) throws(PRReaderFailure) {
      guard let components = URLComponents(string: String(target)),
        GitHubRESTDestination.isAllowed(components),
        let query = components.queryItems, query.count == 2,
        let pageValue = query.first(where: { $0.name == "page" })?.value,
        let page = Self.positiveInteger(pageValue),
        query.contains(URLQueryItem(name: "per_page", value: "100")),
        !components.percentEncodedPath.contains("%")
      else { throw .unavailable }

      let path = components.percentEncodedPath.split(
        separator: "/", omittingEmptySubsequences: false)
      let suffix = route.pathSuffix(for: id.number)
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
