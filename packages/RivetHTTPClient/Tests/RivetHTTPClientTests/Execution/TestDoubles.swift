import Foundation
import RivetHTTPClient

let fixtureResponse = HTTPResponse(
  statusCode: 200,
  headers: [.contentType: "application/json"],
  body: Data("{}".utf8)
)

extension HTTPResponse {
  static let fixture = fixtureResponse
}

final class LockedBox<Value>: @unchecked Sendable {
  private let lock = NSLock()
  private var storage: Value

  init(_ value: Value) {
    storage = value
  }

  var value: Value {
    lock.withLock { storage }
  }

  func set(_ value: Value) {
    lock.withLock { storage = value }
  }
}

struct CapturingTransport: Transport {
  let captured: LockedBox<URLRequest?>
  let response: HTTPResponse

  func execute(_ request: URLRequest) async throws(HTTPClientError) -> HTTPResponse {
    captured.set(request)
    return response
  }
}

struct FailingTransport: Transport {
  func execute(_ request: URLRequest) async throws(HTTPClientError) -> HTTPResponse {
    throw .underlyingFailure(TransportFailure.unavailable)
  }
}

enum TransportFailure: Error, Equatable {
  case unavailable
}
