public protocol RequestAuthorization: Sendable {
  func applying(to request: HTTPRequest) -> HTTPRequest
}
