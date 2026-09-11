import Foundation
import RivetHTTPClient
import Testing

@Suite("Auth flow contracts")
struct AuthTests {
  @Test
  func externalConformersUseExistentialFlowsAndAsyncTransitions() async throws {
    let url = try HTTPURL(#require(URL(string: "https://example.com/auth")))
    let request = HTTPRequest(url: url, method: .get)
    let auth = TestAuth()
    var flow: any AuthFlow = auth.makeFlow(for: request)

    switch await flow.start() {
    case .send(let sentRequest):
      #expect(sentRequest == request)
    case .finish:
      Issue.record("Expected the initial action to send the supplied request.")
    }

    let response = HTTPResponse(statusCode: 200, headers: HTTPHeaders(), body: Data())

    switch await flow.receive(response) {
    case .send:
      Issue.record("Expected the flow to finish after receiving a response.")
    case .finish:
      break
    }
  }
}

private struct TestAuth: Auth {
  func makeFlow(for request: HTTPRequest) -> any AuthFlow {
    TestAuthFlow(request: request)
  }
}

private struct TestAuthFlow: AuthFlow {
  let request: HTTPRequest

  mutating func start() async -> ClientAction {
    .send(request)
  }

  mutating func receive(_ response: HTTPResponse) async -> ClientAction {
    .finish
  }
}
