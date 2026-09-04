import Foundation

public struct Requester: Sendable {
  private let transport: any Transport

  public init(transport: any Transport) {
    self.transport = transport
  }

  public func execute(_ request: HTTPRequest) async throws -> HTTPResponse {
    var urlRequest = URLRequest(url: request.url.value)
    urlRequest.httpMethod = request.method.rawValue
    urlRequest.httpBody = request.body

    for (name, value) in request.headers.values {
      urlRequest.setValue(value, forHTTPHeaderField: name)
    }

    return try await transport.execute(urlRequest)
  }
}
