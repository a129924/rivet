import Foundation

public struct HTTPClient: Sendable {
  private let requester: Requester

  public init(transport: any Transport) {
    requester = Requester(transport: transport)
  }

  public func execute(_ request: HTTPRequest) async throws(HTTPClientError) -> HTTPResponse {
    try await requester.execute(request)
  }

  public func execute(
    _ request: HTTPRequest,
    auth: any Auth
  ) async throws(HTTPClientError) -> HTTPResponse {
    var flow = auth.makeFlow(for: request)
    var action = await flow.start()
    var lastResponse: HTTPResponse?

    while true {
      switch action {
      case .send(let nextRequest):
        let response = try await requester.execute(nextRequest)
        lastResponse = response
        action = await flow.receive(response)
      case .finish:
        guard let lastResponse else {
          throw .authFlowFinishedWithoutResponse
        }
        return lastResponse
      }
    }
  }

  public func request(
    method: HTTPMethod,
    url: HTTPURL,
    headers: HTTPHeaders = HTTPHeaders(),
    body: Data? = nil
  ) async throws(HTTPClientError) -> HTTPResponse {
    try await execute(HTTPRequest(url: url, method: method, headers: headers, body: body))
  }

  public func get(
    url: HTTPURL,
    headers: HTTPHeaders = HTTPHeaders(),
    body: Data? = nil
  ) async throws(HTTPClientError) -> HTTPResponse {
    try await request(method: .get, url: url, headers: headers, body: body)
  }

  public func post(
    url: HTTPURL,
    headers: HTTPHeaders = HTTPHeaders(),
    body: Data? = nil
  ) async throws(HTTPClientError) -> HTTPResponse {
    try await request(method: .post, url: url, headers: headers, body: body)
  }

  public func put(
    url: HTTPURL,
    headers: HTTPHeaders = HTTPHeaders(),
    body: Data? = nil
  ) async throws(HTTPClientError) -> HTTPResponse {
    try await request(method: .put, url: url, headers: headers, body: body)
  }

  public func patch(
    url: HTTPURL,
    headers: HTTPHeaders = HTTPHeaders(),
    body: Data? = nil
  ) async throws(HTTPClientError) -> HTTPResponse {
    try await request(method: .patch, url: url, headers: headers, body: body)
  }

  public func delete(
    url: HTTPURL,
    headers: HTTPHeaders = HTTPHeaders(),
    body: Data? = nil
  ) async throws(HTTPClientError) -> HTTPResponse {
    try await request(method: .delete, url: url, headers: headers, body: body)
  }
}
