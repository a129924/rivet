import RivetHTTPClient

package final class HeadersProvider: Sendable {
  private static let builtInREST = makeRESTDefaults(configuration: .rivet)

  static let standardREST = builtInREST.standardREST
  static let loginAccountREST = builtInREST.login
  static let oauthToken = HeadersProvider(
    headers: [.accept: "application/json", .contentType: "application/x-www-form-urlencoded"])

  let headers: HTTPHeaders

  private init(headers: HTTPHeaders) {
    self.headers = headers
  }

  func makeStandardRESTWithJSONBody() -> HeadersProvider {
    var jsonHeaders = headers
    jsonHeaders.contentType = "application/json"
    return HeadersProvider(headers: jsonHeaders)
  }

  func makePullRequestUnifiedDiffREST() -> HeadersProvider {
    var diffHeaders = headers
    diffHeaders.accept = "application/vnd.github.diff"
    return HeadersProvider(headers: diffHeaders)
  }

  static func makeRESTDefaults(configuration: GitHubHeadersConfiguration) -> (
    standardREST: HeadersProvider, login: HeadersProvider
  ) {
    let standardREST = HeadersProvider(
      headers: [
        .accept: configuration.restAccept,
        .userAgent: configuration.standardUserAgent,
        .custom("X-GitHub-Api-Version"): configuration.apiVersion,
      ])
    let login = HeadersProvider(
      headers: [.accept: configuration.restAccept, .userAgent: configuration.loginUserAgent])
    return (standardREST, login)
  }
}
