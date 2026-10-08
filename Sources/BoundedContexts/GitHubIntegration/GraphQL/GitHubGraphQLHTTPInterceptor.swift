import Apollo
import Foundation

internal struct GitHubGraphQLHTTPInterceptor: HTTPInterceptor {
  @TaskLocal internal static var accessToken: GitHubAccessToken?

  internal func intercept(
    request: URLRequest,
    next: NextHTTPInterceptorFunction
  ) async throws -> HTTPResponse {
    try Task.checkCancellation()
    guard let token = Self.accessToken else {
      throw GitHubGraphQLClientError.authenticationRequired
    }
    var authenticatedRequest = request
    authenticatedRequest.setValue(
      "Bearer " + token.rawValue,
      forHTTPHeaderField: "Authorization"
    )
    let response = try await next(authenticatedRequest)
    try Task.checkCancellation()
    guard (200..<300).contains(response.response.statusCode) else {
      throw GitHubGraphQLClientError.httpStatus(response.response.statusCode)
    }
    return response
  }
}
