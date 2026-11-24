import RivetHTTPClient

package enum GitHubHeaderRequirement: Hashable, Sendable {
  case standardREST
  case loginRuntimeREST
}

package struct GitHubHeadersFactory: Sendable {
  package enum CompositionError: Error, Equatable, Sendable {
    case conflictingRESTRequirements
  }

  package static let standard = Self(inbox: .inboxREST, login: .loginAccountREST)

  private let inbox: HeadersProvider
  private let login: HeadersProvider

  init(configuration: GitHubHeadersConfiguration) {
    let defaults = HeadersProvider.makeRESTDefaults(configuration: configuration)
    self.init(inbox: defaults.inbox, login: defaults.login)
  }

  private init(inbox: HeadersProvider, login: HeadersProvider) {
    self.inbox = inbox
    self.login = login
  }

  package func make(
    requirements: [GitHubHeaderRequirement]
  ) throws(CompositionError) -> HTTPHeaders {
    let unique = Set(requirements)
    guard unique.count <= 1 else { throw .conflictingRESTRequirements }
    return unique.contains(.loginRuntimeREST) ? login.headers : inbox.headers
  }
}
