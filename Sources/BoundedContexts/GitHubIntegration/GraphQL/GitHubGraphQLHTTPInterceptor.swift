import Apollo
import Foundation
import RivetHTTPClient

internal struct GitHubGraphQLHTTPInterceptor: HTTPInterceptor {
  @TaskLocal internal static var accessToken: GitHubAccessToken?

  internal func intercept(
    request: URLRequest,
    next: NextHTTPInterceptorFunction
  ) async throws -> Apollo.HTTPResponse {
    try Task.checkCancellation()
    guard let token = Self.accessToken else {
      throw GitHubGraphQLClientError.authenticationRequired
    }
    var authenticatedRequest = request
    do {
      let auth = try BearerAuth(token: token.rawValue)
      authenticatedRequest.allHTTPHeaderFields = auth.applying(
        to: request.allHTTPHeaderFields ?? [:])
    } catch AuthorizationHeaderError.invalidToken {
      throw GitHubGraphQLClientError.invalidAuthorizationToken
    }
    let response = try await next(authenticatedRequest)
    try Task.checkCancellation()
    guard (200..<300).contains(response.response.statusCode) else {
      throw GitHubGraphQLClientError.httpStatus(response.response.statusCode)
    }
    return response
  }
}
