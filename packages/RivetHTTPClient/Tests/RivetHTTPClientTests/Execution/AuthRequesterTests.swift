import Foundation
import Testing
@testable import RivetHTTPClient

@Suite("AuthRequester")
struct AuthRequesterTests {
  @Test
  func requesterIsSendable() {
    assertSendable(AuthRequester.self)
  }

  @Test
  func sendsTheStartActionAndReturnsItsResponseAfterOneReceive() async throws {
    let originalRequest = try makeAuthRequest(path: "original")
    let sentRequest = try makeAuthRequest(path: "auth")
    let response = HTTPResponse.fixture
    let flow = RecordingAuthState(startAction: .send(sentRequest), receiveActions: [.finish])
    let transport = SequencedTransportState(outcomes: [.success(response)])
    let requester = Requester(transport: SequencedTransport(state: transport))
    let authRequester = AuthRequester(requester: requester, auth: RecordingAuth(state: flow))

    let result = try await authRequester.execute(originalRequest)

    #expect(result == response)
    #expect(flow.madeFlowRequests == [originalRequest])
    #expect(flow.starts == 1)
    #expect(flow.received == [response])
    #expect(transport.executedRequests.map(\.url) == [sentRequest.url.value])
  }

  @Test
  func followsMultipleSendReceiveActionsAndReturnsTheLastResponse() async throws {
    let originalRequest = try makeAuthRequest(path: "original")
    let firstRequest = try makeAuthRequest(path: "first")
    let secondRequest = try makeAuthRequest(path: "second")
    let firstResponse = HTTPResponse(
      statusCode: 201,
      headers: HTTPHeaders(),
      body: Data("first".utf8)
    )
    let secondResponse = HTTPResponse(
      statusCode: 202,
      headers: HTTPHeaders(),
      body: Data("second".utf8)
    )
    let flow = RecordingAuthState(
      startAction: .send(firstRequest),
      receiveActions: [.send(secondRequest), .finish],
    )
    let transport = SequencedTransportState(
      outcomes: [.success(firstResponse), .success(secondResponse)]
    )
    let requester = Requester(transport: SequencedTransport(state: transport))
    let authRequester = AuthRequester(requester: requester, auth: RecordingAuth(state: flow))

    let result = try await authRequester.execute(originalRequest)

    #expect(result == secondResponse)
    #expect(flow.madeFlowRequests == [originalRequest])
    #expect(flow.starts == 1)
    #expect(flow.received == [firstResponse, secondResponse])
    #expect(
      transport.executedRequests.map(\.url) == [firstRequest.url.value, secondRequest.url.value]
    )
  }

  @Test
  func rejectsDirectFinishWithoutSendingOrReceiving() async throws {
    let request = try makeAuthRequest(path: "direct-finish")
    let flow = RecordingAuthState(startAction: .finish, receiveActions: [])
    let transport = SequencedTransportState(outcomes: [])
    let requester = Requester(transport: SequencedTransport(state: transport))
    let authRequester = AuthRequester(requester: requester, auth: RecordingAuth(state: flow))

    let error = try #require(
      await #expect(throws: HTTPClientError.self) {
        try await authRequester.execute(request)
      }
    )

    guard case .authFlowFinishedWithoutResponse = error else {
      Issue.record("Expected authFlowFinishedWithoutResponse, got \(String(describing: error))")
      return
    }
    #expect(flow.madeFlowRequests == [request])
    #expect(flow.starts == 1)
    #expect(flow.received.isEmpty)
    #expect(transport.executedRequests.isEmpty)
  }

  @Test
  func createsANewFlowForEachExecution() async throws {
    let firstRequest = try makeAuthRequest(path: "first")
    let secondRequest = try makeAuthRequest(path: "second")
    let response = HTTPResponse.fixture
    let flow = RecordingAuthState(
      startAction: .send(firstRequest),
      receiveActions: [.finish, .finish]
    )
    let transport = SequencedTransportState(outcomes: [.success(response), .success(response)])
    let requester = Requester(transport: SequencedTransport(state: transport))
    let authRequester = AuthRequester(requester: requester, auth: RecordingAuth(state: flow))

    _ = try await authRequester.execute(firstRequest)
    _ = try await authRequester.execute(secondRequest)

    #expect(flow.madeFlowRequests == [firstRequest, secondRequest])
    #expect(flow.starts == 2)
    #expect(flow.received == [response, response])
  }

  @Test
  func propagatesTheFirstRequesterErrorWithoutReceivingOrRetrying() async throws {
    let request = try makeAuthRequest(path: "first-failure")
    let flow = RecordingAuthState(startAction: .send(request), receiveActions: [])
    let transport = SequencedTransportState(
      outcomes: [.failure(.underlyingFailure(TransportFailure.unavailable))]
    )
    let requester = Requester(transport: SequencedTransport(state: transport))
    let authRequester = AuthRequester(requester: requester, auth: RecordingAuth(state: flow))

    let error = try #require(
      await #expect(throws: HTTPClientError.self) {
        try await authRequester.execute(request)
      }
    )

    assertUnexpectedTransportFailure(error)
    #expect(flow.received.isEmpty)
    #expect(transport.executedRequests.count == 1)
  }

  @Test
  func propagatesFollowUpRequesterErrorWithoutAnotherReceiveOrRetry() async throws {
    let firstRequest = try makeAuthRequest(path: "first")
    let secondRequest = try makeAuthRequest(path: "second")
    let firstResponse = HTTPResponse.fixture
    let flow = RecordingAuthState(
      startAction: .send(firstRequest),
      receiveActions: [.send(secondRequest)]
    )
    let transport = SequencedTransportState(outcomes: [
      .success(firstResponse),
      .failure(.underlyingFailure(TransportFailure.unavailable)),
    ])
    let requester = Requester(transport: SequencedTransport(state: transport))
    let authRequester = AuthRequester(requester: requester, auth: RecordingAuth(state: flow))

    let error = try #require(
      await #expect(throws: HTTPClientError.self) {
        try await authRequester.execute(firstRequest)
      }
    )

    assertUnexpectedTransportFailure(error)
    #expect(flow.received == [firstResponse])
    #expect(
      transport.executedRequests.map(\.url) == [firstRequest.url.value, secondRequest.url.value]
    )
  }

  @Test(arguments: [404, 503])
  func passesRawNonSuccessResponsesToTheFlow(statusCode: Int) async throws {
    let request = try makeAuthRequest(path: "status-\(statusCode)")
    let response = HTTPResponse(
      statusCode: statusCode,
      headers: HTTPHeaders(),
      body: Data("raw".utf8)
    )
    let flow = RecordingAuthState(startAction: .send(request), receiveActions: [.finish])
    let requester = Requester(
      transport: SequencedTransport(
        state: SequencedTransportState(outcomes: [.success(response)])
      )
    )
    let authRequester = AuthRequester(requester: requester, auth: RecordingAuth(state: flow))

    let result = try await authRequester.execute(request)

    #expect(result == response)
    #expect(flow.received == [response])
  }
}

private func makeAuthRequest(path: String) throws -> HTTPRequest {
  let url = try HTTPURL(#require(URL(string: "https://example.com/\(path)")))
  return HTTPRequest(url: url, method: .get)
}

private func assertSendable<Value: Sendable>(_ value: Value.Type) {}

private func assertUnexpectedTransportFailure(_ error: HTTPClientError) {
  guard case .underlyingFailure(let underlyingError) = error else {
    Issue.record("Expected underlyingFailure HTTPClientError, got \(String(describing: error))")
    return
  }
  #expect((underlyingError as? TransportFailure) == .unavailable)
}
