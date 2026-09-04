public struct HTTPClient: Sendable {
  private let requester: Requester

  public init(transport: any Transport) {
    requester = Requester(transport: transport)
  }

  public func execute(_ request: HTTPRequest) async throws -> HTTPResponse {
    try await requester.execute(request)
  }
}
