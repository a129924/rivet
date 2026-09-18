import Foundation
import RivetHTTPClient
import Testing

@Suite("BearerAuth")
struct BearerAuthTests {
  @Test
  func injectsBearerAuthorization() throws {
    let request = HTTPRequest(
      url: try HTTPURL(#require(URL(string: "https://example.com/issues"))),
      method: .get
    )

    let authorizedRequest = BearerAuth(token: "token-123").applying(to: request)

    #expect(authorizedRequest.headers.authorization == "Bearer token-123")
    #expect(authorizedRequest.headers.values == ["authorization": "Bearer token-123"])
  }

  @Test(arguments: ["Authorization", "authorization", "aUtHoRiZaTiOn"])
  func replacesExistingAuthorizationRegardlessOfCasing(headerName: String) throws {
    let request = HTTPRequest(
      url: try HTTPURL(#require(URL(string: "https://example.com/issues"))),
      method: .get,
      headers: HTTPHeaders([
        headerName: "Basic old-credentials",
        "X-Rivet-Trace": "trace-123",
      ])
    )

    let authorizedRequest = BearerAuth(token: "token-123").applying(to: request)

    #expect(authorizedRequest.headers.authorization == "Bearer token-123")
    #expect(
      authorizedRequest.headers.values == [
        "authorization": "Bearer token-123",
        "x-rivet-trace": "trace-123",
      ])
  }

  @Test
  func preservesTheOriginalRequestAndAllNonAuthorizationFields() throws {
    let url = try HTTPURL(#require(URL(string: "https://example.com/issues")))
    let body = Data("payload".utf8)
    let headers = HTTPHeaders([
      "Authorization": "Basic old-credentials",
      "Accept": "application/json",
      "X-Rivet-Trace": "trace-123",
    ])
    let request = HTTPRequest(url: url, method: .post, headers: headers, body: body)

    let authorizedRequest = BearerAuth(token: "token-123").applying(to: request)

    #expect(request.url == url)
    #expect(request.method == .post)
    #expect(request.headers == headers)
    #expect(request.body == body)
    #expect(authorizedRequest.url == url)
    #expect(authorizedRequest.method == .post)
    #expect(authorizedRequest.body == body)
    #expect(authorizedRequest.headers.accept == "application/json")
    #expect(authorizedRequest.headers.value(for: "x-rivet-trace") == "trace-123")
    #expect(authorizedRequest.headers.authorization == "Bearer token-123")
  }

  @Test
  func appliesBearerAuthorizationThroughTheRequestAuthorizationExistential() throws {
    let request = HTTPRequest(
      url: try HTTPURL(#require(URL(string: "https://example.com/issues"))),
      method: .get
    )
    let authorization: any RequestAuthorization = BearerAuth(token: "token-123")

    let authorizedRequest = authorization.applying(to: request)

    #expect(authorizedRequest.headers.authorization == "Bearer token-123")
  }

  @Test
  func redactsTokenFromDescriptionsAndReflection() {
    let fakeTokenSentinel = "fake-bearer-token-sentinel-do-not-log"
    let authorization = BearerAuth(token: fakeTokenSentinel)
    let mirror = Mirror(reflecting: authorization)
    let outputs = [
      String(describing: authorization),
      authorization.debugDescription,
      String(reflecting: authorization),
      String(describing: mirror),
      String(describing: mirror.children.map(\.value)),
    ]

    for output in outputs {
      #expect(!output.contains(fakeTokenSentinel))
    }

    #expect(mirror.children.isEmpty)
  }
}
