import Foundation
import RivetHTTPClient
import Testing

@testable import GitHubIntegration

@Suite("Login account probe")
struct GitHubLoginAccountProbeTests {
  @Test func validAccountUsesOneAuthorizedRequest() async throws {
    let transport = LoginProbeTransport(status: 200, body: "{\"id\":1,\"login\":\"octocat\"}")
    try await GitHubLoginAccountProbe(client: HTTPClient(transport: transport)).validate(
      token: "fixture")
    let requests = await transport.requests
    #expect(requests.count == 1)
    #expect(requests.first?.httpMethod == "GET")
    #expect(requests.first?.url?.absoluteString == "https://api.github.com/user")
    #expect(requests.first?.value(forHTTPHeaderField: "Authorization") == "Bearer fixture")
    #expect(requests.first?.value(forHTTPHeaderField: "User-Agent") == "RivetLoginRuntime")
    #expect(requests.first?.value(forHTTPHeaderField: "Accept") == "application/vnd.github+json")
    #expect(requests.first?.value(forHTTPHeaderField: "X-GitHub-Api-Version") == nil)
  }

  @Test func usesInjectedLoginHeadersBeforeApplyingBearer() async throws {
    let configuration = try GitHubHeadersConfiguration(
      restAccept: "application/json", standardUserAgent: "Inbox Fixture",
      loginUserAgent: "Login Fixture", apiVersion: "2040-01-01")
    let transport = LoginProbeTransport(status: 200, body: #"{"id":1,"login":"octocat"}"#)
    let probe = GitHubLoginAccountProbe(
      client: HTTPClient(transport: transport),
      headersFactory: GitHubHeadersFactory(configuration: configuration))

    try await probe.validate(token: "fixture")
    let request = try #require(await transport.requests.first)
    #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
    #expect(request.value(forHTTPHeaderField: "User-Agent") == "Login Fixture")
    #expect(request.value(forHTTPHeaderField: "X-GitHub-Api-Version") == nil)
    #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer fixture")
  }

  @Test(arguments: [
    "{}", "not-json", "{\"id\":0,\"login\":\"ok\"}",
    "{\"id\":-1,\"login\":\"ok\"}", "{\"id\":1,\"login\":\" \"}",
    "{\"id\":1.5,\"login\":\"ok\"}", "{\"id\":\"1\",\"login\":\"ok\"}",
  ])
  func invalidIdentityIsRejected(_ body: String) async {
    let transport = LoginProbeTransport(status: 200, body: body)
    await #expect(throws: (any Error).self) {
      try await GitHubLoginAccountProbe(client: HTTPClient(transport: transport)).validate(
        token: "fixture")
    }
    #expect(await transport.requests.count == 1)
  }

  @Test(arguments: [201, 302, 401, 403, 500])
  func rejectsStatusWithoutRetry(_ status: Int) async {
    let transport = LoginProbeTransport(status: status, body: "{\"id\":1,\"login\":\"ok\"}")
    await #expect(throws: (any Error).self) {
      try await GitHubLoginAccountProbe(client: HTTPClient(transport: transport)).validate(
        token: "fixture")
    }
    #expect(await transport.requests.count == 1)
  }

  @Test func transportFailureIsNotRetried() async {
    let transport = FailedLoginTransport()
    await #expect(throws: (any Error).self) {
      try await GitHubLoginAccountProbe(client: HTTPClient(transport: transport)).validate(
        token: "fixture")
    }
    #expect(await transport.calls == 1)
  }

  @Test func invalidBearerDoesNotReachTransport() async {
    let transport = LoginProbeTransport(status: 200, body: "{}")
    await #expect(throws: (any Error).self) {
      try await GitHubLoginAccountProbe(client: HTTPClient(transport: transport)).validate(
        token: "bad\r\ntoken")
    }
    #expect(await transport.requests.isEmpty)
  }
}

actor LoginProbeTransport: Transport {
  let status: Int
  let body: String
  var requests: [URLRequest] = []

  init(status: Int, body: String) {
    self.status = status
    self.body = body
  }

  func execute(_ request: URLRequest) async throws(HTTPClientError) -> HTTPResponse {
    requests.append(request)
    return HTTPResponse(statusCode: status, headers: [:], body: Data(body.utf8))
  }
}

actor FailedLoginTransport: Transport {
  var calls = 0
  func execute(_ request: URLRequest) async throws(HTTPClientError) -> HTTPResponse {
    calls += 1
    throw .networkFailure(URLError(.notConnectedToInternet))
  }
}
