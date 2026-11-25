import RivetHTTPClient

package enum GitHubHeaderRequirement: Hashable, Sendable {
  case standardREST
  case loginRuntimeREST
}

package struct GitHubHeadersFactory: Sendable {
  package enum CompositionError: Error, Equatable, Sendable {
    case conflictingRESTRequirements
  }

  package static let standard = Self(standardREST: .standardREST, login: .loginAccountREST)

  private let standardREST: HeadersProvider
  private let login: HeadersProvider

  init(configuration: GitHubHeadersConfiguration) {
    let defaults = HeadersProvider.makeRESTDefaults(configuration: configuration)
    self.init(standardREST: defaults.standardREST, login: defaults.login)
  }

  private init(standardREST: HeadersProvider, login: HeadersProvider) {
    self.standardREST = standardREST
    self.login = login
  }

  package func make(
    requirements: [GitHubHeaderRequirement]
  ) throws(CompositionError) -> HTTPHeaders {
    let unique = Set(requirements)
    guard unique.count <= 1 else { throw .conflictingRESTRequirements }
    return unique.contains(.loginRuntimeREST) ? login.headers : standardREST.headers
  }
}
