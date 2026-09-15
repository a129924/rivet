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

final class RecordingAuthState: @unchecked Sendable {
  private let lock = NSLock()
  private let startAction: ClientAction
  private var receiveActions: [ClientAction]
  private var makeFlowRequests: [HTTPRequest] = []
  private var startCallCount = 0
  private var receivedResponses: [HTTPResponse] = []

  init(startAction: ClientAction, receiveActions: [ClientAction]) {
    self.startAction = startAction
    self.receiveActions = receiveActions
  }

  func recordMakeFlow(for request: HTTPRequest) {
    lock.withLock {
      makeFlowRequests.append(request)
    }
  }

  func start() -> ClientAction {
    lock.withLock {
      startCallCount += 1
      return startAction
    }
  }

  func receive(_ response: HTTPResponse) -> ClientAction {
    lock.withLock {
      receivedResponses.append(response)
      return receiveActions.removeFirst()
    }
  }

  var madeFlowRequests: [HTTPRequest] {
    lock.withLock { makeFlowRequests }
  }

  var starts: Int {
    lock.withLock { startCallCount }
  }

  var received: [HTTPResponse] {
    lock.withLock { receivedResponses }
  }
}

struct RecordingAuth: Auth {
  let state: RecordingAuthState

  func makeFlow(for request: HTTPRequest) -> any AuthFlow {
    state.recordMakeFlow(for: request)
    return RecordingAuthFlow(state: state)
  }
}

private struct RecordingAuthFlow: AuthFlow {
  let state: RecordingAuthState

  mutating func start() async -> ClientAction {
    state.start()
  }

  mutating func receive(_ response: HTTPResponse) async -> ClientAction {
    state.receive(response)
  }
}

final class SequencedTransportState: @unchecked Sendable {
  private let lock = NSLock()
  private var outcomes: [Result<HTTPResponse, HTTPClientError>]
  private var requests: [URLRequest] = []

  init(outcomes: [Result<HTTPResponse, HTTPClientError>]) {
    self.outcomes = outcomes
  }

  func execute(_ request: URLRequest) throws(HTTPClientError) -> HTTPResponse {
    lock.lock()
    defer { lock.unlock() }

    requests.append(request)
    guard !outcomes.isEmpty else {
      throw HTTPClientError.underlyingFailure(TransportFailure.unavailable)
    }
    switch outcomes.removeFirst() {
    case .success(let response):
      return response
    case .failure(let error):
      throw error
    }
  }

  var executedRequests: [URLRequest] {
    lock.withLock { requests }
  }
}

struct SequencedTransport: Transport {
  let state: SequencedTransportState

  func execute(_ request: URLRequest) async throws(HTTPClientError) -> HTTPResponse {
    try state.execute(request)
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

final class RecordingTransportState: @unchecked Sendable {
  private let lock = NSLock()
  private var requests: [URLRequest] = []

  func record(_ request: URLRequest) {
    lock.withLock {
      requests.append(request)
    }
  }

  var executedRequests: [URLRequest] {
    lock.withLock { requests }
  }
}

struct RecordingTransport: Transport {
  let state: RecordingTransportState
  let response: HTTPResponse

  func execute(_ request: URLRequest) async throws(HTTPClientError) -> HTTPResponse {
    state.record(request)
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
