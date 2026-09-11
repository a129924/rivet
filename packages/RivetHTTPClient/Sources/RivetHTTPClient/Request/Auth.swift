public enum ClientAction: Sendable {
  case send(HTTPRequest)
  case finish
}

public protocol Auth: Sendable {
  func makeFlow(for request: HTTPRequest) -> any AuthFlow
}

public protocol AuthFlow: Sendable {
  mutating func start() async -> ClientAction
  mutating func receive(_ response: HTTPResponse) async -> ClientAction
}
