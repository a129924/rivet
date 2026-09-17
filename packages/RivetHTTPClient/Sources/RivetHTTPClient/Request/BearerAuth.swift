public struct BearerAuth: RequestAuthorization {
  private let token: String

  public init(token: String) {
    self.token = token
  }

  public func applying(to request: HTTPRequest) -> HTTPRequest {
    var headers = request.headers
    headers.authorization = "Bearer \(token)"

    return HTTPRequest(
      url: request.url,
      method: request.method,
      headers: headers,
      body: request.body
    )
  }
}
