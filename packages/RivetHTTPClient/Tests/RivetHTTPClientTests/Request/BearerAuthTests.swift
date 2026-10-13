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

    let authorizedRequest = try BearerAuth(token: "token-123").applying(to: request)

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

    let authorizedRequest = try BearerAuth(token: "token-123").applying(to: request)

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

    let authorizedRequest = try BearerAuth(token: "token-123").applying(to: request)

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
    let authorization: any RequestAuthorization = try BearerAuth(token: "token-123")

    let authorizedRequest = authorization.applying(to: request)

    #expect(authorizedRequest.headers.authorization == "Bearer token-123")
  }

  @Test
  func redactsTokenFromDescriptionsAndReflection() throws {
    let fakeTokenSentinel = "fake-bearer-token-sentinel-do-not-log"
    let authorization = try BearerAuth(token: fakeTokenSentinel)
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

  @Test(arguments: ["token-123", "AZaz09-._~+/", "a", "a=", "a==", "a===", "a========"])
  func headersOverloadUsesSharedRules(token: String) throws {
    let auth = try BearerAuth(token: token)
    for headers in [
      [:],
      [
        "Authorization": "old", "authorization": "stale",
        "AUTHORIZATION": "old", "aUtHoRiZaTiOn": "old", "X-Trace": "Keep",
        "x-trace": "separate", "X-Empty": "", "X-Unicode": "繁體中文",
      ],
    ] {
      let snapshot = headers
      let result = auth.applying(to: headers)
      #expect(result == (try AuthorizationHeader.applyingBearer(token: token, to: headers)))
      #expect(auth.applying(to: result) == result)
      #expect(headers == snapshot)
    }
  }

  @Test(arguments: [
    "", "=", "===", "=abc", "a=b", "a==b", " a", "a ", "a b", "a\tb",
    "a\r", "a\n", "a\r\nInjected: value", "a\0b", "é", "a😀", "a:", "a@", "a%", "a\\b", "a?",
  ])
  func rejectsInvalidTokens(token: String) {
    #expect(throws: AuthorizationHeaderError.invalidToken) { try BearerAuth(token: token) }
  }

  @Test
  func requestOverloadMatchesHeadersAndIsIdempotent() throws {
    let auth = try BearerAuth(token: "new")
    let request = HTTPRequest(
      url: try HTTPURL(#require(URL(string: "https://example.com/issues"))),
      method: .post, headers: HTTPHeaders(["AUTHORIZATION": "old", "X-Trace": "keep"]),
      body: Data("payload".utf8))
    let result = auth.applying(to: request)
    #expect(result.headers == HTTPHeaders(auth.applying(to: request.headers.values)))
    #expect(auth.applying(to: result) == result)
  }

  @Test
  func initializationErrorDoesNotExposeToken() throws {
    let sentinel = "invalid-token-sentinel-do-not-log!"
    let error = try #require(
      #expect(throws: AuthorizationHeaderError.self) {
        try BearerAuth(token: sentinel)
      })
    #expect(error == .invalidToken)
    #expect(!String(reflecting: error).contains(sentinel))
    #expect(!String(describing: error).contains(sentinel))
    #expect(Mirror(reflecting: error).children.isEmpty)
  }
}
