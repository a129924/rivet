public struct BearerAuth:
  RequestAuthorization,
  CustomStringConvertible,
  CustomDebugStringConvertible,
  CustomReflectable
// swiftlint:disable:next opening_brace
{
  private let authorizationValue: String

  /// 拒絕不符合 Bearer 文法的 token；錯誤不攜帶 token。
  public init(token: String) throws(AuthorizationHeaderError) {
    authorizationValue = try AuthorizationHeader.bearerValue(token: token)
  }

  /// 以單一 Authorization 取代大小寫變體，保留其他 entries 且不修改輸入。
  public func applying(to headers: [String: String]) -> [String: String] {
    AuthorizationHeader.replacingAuthorization(value: authorizationValue, in: headers)
  }

  public func applying(to request: HTTPRequest) -> HTTPRequest {
    let headers = HTTPHeaders(applying(to: request.headers.values))

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
