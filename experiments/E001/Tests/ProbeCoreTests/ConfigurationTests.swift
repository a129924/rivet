import Foundation
import Testing

@testable import ProbeCore

struct ConfigurationTests {
  @Test func validConfigurationAndURL() throws {
    let config = try ProbeConfiguration(arguments: ["--client-id", "test-client"])
    #expect(config.timeoutSeconds == 180)
    let state = try ProbeState.generate()
    #expect(state.count == 64)
    #expect(state.allSatisfy { "0123456789abcdef".contains($0) })
    #expect(state != (try ProbeState.generate()))
    let url = try #require(config.authorizationURL(port: 43210, state: state))
    let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
    #expect(components.host == "github.com")
    #expect(
      components.queryItems?.first(where: { $0.name == "redirect_uri" })?.value
        == "http://127.0.0.1:43210/oauth/callback")
    #expect(components.queryItems?.first(where: { $0.name == "state" })?.value == state)
  }

  @Test(arguments: [
    [], ["--client-id"], ["--client-id", ""], ["--client-id", " "],
    ["--client-id", "x", "--unknown", "y"], ["--client-id", "x", "--client-id", "y"],
    ["--client-id", "x", "--timeout-seconds", "0"],
    ["--client-id", "x", "--timeout-seconds", "-1"],
    ["--client-id", "x", "--timeout-seconds", "1.5"],
    ["--client-id", "x", "--timeout-seconds", "99999999999999999999999999999999"],
  ])
  func invalidConfigurationFails(arguments: [String]) {
    #expect(throws: ConfigurationError.self) { try ProbeConfiguration(arguments: arguments) }
  }

  @Test func positiveTimeoutAccepted() throws {
    #expect(
      try ProbeConfiguration(arguments: ["--client-id", "x", "--timeout-seconds", "1"])
        .timeoutSeconds == 1)
  }

  @Test func boundedHeaderParsing() {
    var partial = HTTPHeader()
    #expect(partial.append(Data("GET /oauth/call".utf8)) == .incomplete)
    #expect(
      partial.append(Data("back?code=x&state=s HTTP/1.1\r\nHost: localhost\r\n\r\n".utf8))
        == .request(method: "GET", target: "/oauth/callback?code=x&state=s"))
    var oversized = HTTPHeader()
    #expect(oversized.append(Data(repeating: 65, count: HTTPHeader.maximumBytes)) == .rejected)
    var malformed = HTTPHeader()
    #expect(malformed.append(Data("bad request\r\n\r\n".utf8)) == .rejected)
  }
}
