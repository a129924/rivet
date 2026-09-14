import Foundation

struct AuthRequester: Sendable {
  private let requester: Requester
  private let auth: any Auth

  init(requester: Requester, auth: any Auth) {
    self.requester = requester
    self.auth = auth
  }

  func execute(_ request: HTTPRequest) async throws(HTTPClientError) -> HTTPResponse {
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
}
