import Foundation

enum GitHubUnreadNotificationsPageLinks {
  static func nextPage(
    link: String?, after page: Int
  ) throws(GitHubUnreadNotificationsFailure) -> Int? {
    guard let link else { return nil }
    let pages = try readPages(from: link)
    let next = pages["next"]
    let last = pages["last"]
    if let next {
      let (expected, overflow) = page.addingReportingOverflow(1)
      guard !overflow, next == expected, last.map({ $0 >= next }) ?? true else {
        throw .incompletePagination
      }
    } else if let last, last != page {
      throw .incompletePagination
    }
    return next
  }

  private static func readPages(
    from link: String
  ) throws(GitHubUnreadNotificationsFailure) -> [String: Int] {
    var cursor = link[...]
    var pages: [String: Int] = [:]

    while true {
      cursor = cursor.drop(while: isWhitespace)
      guard let target = cursor.prefixMatch(of: /<([^<>\s]+)>/) else {
        throw .incompletePagination
      }
      cursor = cursor[target.range.upperBound...]
      let parameters = try readParameters(from: &cursor)
      let relations = parameters.relations.intersection(["next", "last"])
      if !relations.isEmpty {
        guard !parameters.hasAnchor else { throw .incompletePagination }
        let targetPage = try pageNumber(target.output.1)
        for relation in relations {
          guard pages.updateValue(targetPage, forKey: relation) == nil else {
            throw .incompletePagination
          }
        }
      }

      cursor = cursor.drop(while: isWhitespace)
      if cursor.isEmpty { break }
      guard cursor.removeFirst() == "," else { throw .incompletePagination }
    }
    return pages
  }

  private static func readParameters(
    from cursor: inout Substring
  ) throws(GitHubUnreadNotificationsFailure) -> (relations: Set<String>, hasAnchor: Bool) {
    var relations: Set<String>?
    var hasAnchor = false
    let parameter =
      #/[ \t]*;[ \t]*([!#$%&'*+.^_\x60|~0-9A-Za-z-]+)[ \t]*=[ \t]*("(?:[^"\\\r\n]|\\[^\r\n])*"|[!#$%&'*+.^_\x60|~0-9A-Za-z-]+)/#
    while let match = cursor.prefixMatch(of: parameter) {
      cursor = cursor[match.range.upperBound...]
      let name = match.output.1.lowercased()
      if name == "anchor" { hasAnchor = true }
      guard name == "rel" else { continue }
      guard relations == nil else { throw .incompletePagination }
      let value = match.output.2
      let relationValue =
        value.first == "\""
        ? value.dropFirst().dropLast().replacingOccurrences(
          of: #"\\(.)"#, with: "$1", options: .regularExpression)
        : String(value)
      let tokens = relationValue.split(whereSeparator: isWhitespace)
      guard !tokens.isEmpty,
        tokens.allSatisfy({
          $0.wholeMatch(of: /[A-Za-z][A-Za-z0-9.-]*/) != nil
            || URL(string: String($0), encodingInvalidCharacters: false)?.scheme != nil
        })
      else { throw .incompletePagination }
      let names = Set(tokens.map { $0.lowercased() })
      guard names.count == tokens.count else { throw .incompletePagination }
      relations = names
    }
    guard let relations else { throw .incompletePagination }
    return (relations, hasAnchor)
  }

  private static func pageNumber(
    _ target: Substring
  ) throws(GitHubUnreadNotificationsFailure) -> Int {
    guard let url = URL(string: String(target), encodingInvalidCharacters: false),
      let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
      GitHubRESTDestination.isAllowed(components),
      components.percentEncodedPath == GitHubUnreadNotificationsEndpoint.path
    else { throw .incompletePagination }

    var values: [String: String] = [:]
    for item in components.queryItems ?? [] {
      guard let value = item.value, !value.isEmpty,
        values.updateValue(value, forKey: item.name) == nil
      else { throw .incompletePagination }
    }
    for expected in GitHubUnreadNotificationsEndpoint.scope {
      if let actual = values.removeValue(forKey: expected.name), actual != expected.value {
        throw .incompletePagination
      }
    }
    guard let rawPage = values.removeValue(forKey: GitHubUnreadNotificationsEndpoint.pageParameter),
      values.isEmpty, rawPage.utf8.allSatisfy({ (48...57).contains($0) }),
      let page = Int(rawPage), page > 0
    else { throw .incompletePagination }
    return page
  }

  private static func isWhitespace(_ character: Character) -> Bool {
    character == " " || character == "\t"
  }
}
