public protocol AsyncRequestAuthorization: Sendable {
  func applying(to request: HTTPRequest) async throws -> HTTPRequest
}
