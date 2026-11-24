import RivetHTTPClient

package final class HeadersProvider: Sendable {
  private static let builtInREST = makeRESTDefaults(configuration: .rivet)

  static let inboxREST = builtInREST.inbox
  static let loginAccountREST = builtInREST.login
  static let oauthToken = HeadersProvider(
    headers: [.accept: "application/json", .contentType: "application/x-www-form-urlencoded"])

  let headers: HTTPHeaders

  private init(headers: HTTPHeaders) {
    self.headers = headers
  }

  static func makeRESTDefaults(configuration: GitHubHeadersConfiguration) -> (
    inbox: HeadersProvider, login: HeadersProvider
  ) {
    let inbox = HeadersProvider(
      headers: [
        .accept: configuration.restAccept,
        .userAgent: configuration.standardUserAgent,
        .custom("X-GitHub-Api-Version"): configuration.apiVersion,
      ])
    let login = HeadersProvider(
      headers: [.accept: configuration.restAccept, .userAgent: configuration.loginUserAgent])
    return (inbox, login)
  }
}
