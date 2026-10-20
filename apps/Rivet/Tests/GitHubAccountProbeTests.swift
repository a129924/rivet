import Foundation
import GitHubIntegration
import RivetHTTPClient
import Testing

@testable import Rivet

struct GitHubAccountProbeTests {
  @Test func requiresHTTP200AndValidIdentity() async throws {
    let valid = ProbeFixtureClient(status: 200, body: "{\"login\":\"fixture-user\",\"id\":42}")
    #expect(try await GitHubAccountProbe.read(client: valid).id == 42)
    for (status, body) in [(403, "{}"), (200, "{}"), (200, "{\"login\":\"\",\"id\":0}")] {
      await #expect(throws: (any Error).self) {
        try await GitHubAccountProbe.read(client: ProbeFixtureClient(status: status, body: body))
      }
    }
  }
}

struct ProbeFixtureClient: GitHubRestClient {
  let status: Int
  let body: String
  func executeGet(_ request: HTTPRequest) async throws -> HTTPResponse {
    #expect(request.url.value.absoluteString == "https://api.github.com/user")
    #expect(request.body == nil)
    return HTTPResponse(statusCode: status, headers: [:], body: Data(body.utf8))
  }
  func executePost(_ request: HTTPRequest) async throws -> HTTPResponse {
    throw GitHubConnectionFailure.unavailable
  }
  func executePut(_ request: HTTPRequest) async throws -> HTTPResponse {
    throw GitHubConnectionFailure.unavailable
  }
  func executePatch(_ request: HTTPRequest) async throws -> HTTPResponse {
    throw GitHubConnectionFailure.unavailable
  }
}
