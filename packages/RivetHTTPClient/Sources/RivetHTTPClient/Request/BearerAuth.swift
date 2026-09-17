public struct BearerAuth:
  RequestAuthorization,
  CustomStringConvertible,
  CustomDebugStringConvertible,
  CustomReflectable
// swiftlint:disable:next opening_brace
{
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

  public var description: String {
    "BearerAuth(redacted)"
  }

  public var debugDescription: String {
    description
  }

  public var customMirror: Mirror {
    Mirror(self, children: [], displayStyle: .struct)
  }
}
