import Foundation
import RivetHTTPClient
import Testing

@Suite("HTTPRequest")
struct HTTPRequestTests {
  @Test
  func exposesStandardHeaderNameConstants() {
    #expect(HTTPHeaderName.accept == "accept")
    #expect(HTTPHeaderName.authorization == "authorization")
    #expect(HTTPHeaderName.contentType == "content-type")
    #expect(HTTPHeaderName.userAgent == "user-agent")
    #expect(HTTPHeaderName.etag == "etag")
    #expect(HTTPHeaderName.ifNoneMatch == "if-none-match")
    #expect(HTTPHeaderName.location == "location")
    #expect(HTTPHeaderName.link == "link")
    #expect(HTTPHeaderName.retryAfter == "retry-after")
  }

  @Test
  func readsStandardHeadersUsingComputedProperties() {
    let headers = HTTPHeaders(
      dictionaryLiteral: ("aCcEpT", "application/json"),
      ("AUTHORIZATION", "Bearer token"),
      ("Content-Type", "application/json; charset=utf-8"),
      ("USER-agent", "Rivet"),
      ("ETag", "tag-value"),
      ("If-None-Match", "prior-tag"),
      ("LOCATION", "https://example.com/redirect"),
      ("Link", "<https://example.com/page>; rel=next"),
      ("Retry-After", "30")
    )

    #expect(headers.accept == "application/json")
    #expect(headers.authorization == "Bearer token")
    #expect(headers.contentType == "application/json; charset=utf-8")
    #expect(headers.userAgent == "Rivet")
    #expect(headers.etag == "tag-value")
    #expect(headers.ifNoneMatch == "prior-tag")
    #expect(headers.location == "https://example.com/redirect")
    #expect(headers.link == "<https://example.com/page>; rel=next")
    #expect(headers.retryAfter == "30")
  }

  @Test
  func looksUpHeadersCaseInsensitivelyIncludingCustomNames() {
    let headers = HTTPHeaders(
      dictionaryLiteral: ("Content-Type", "application/json"),
      ("X-Rivet-Trace", "trace-123")
    )

    #expect(headers.value(for: "CONTENT-TYPE") == "application/json")
    #expect(headers.value(for: HTTPHeaderName.contentType) == "application/json")
    #expect(headers.value(for: "x-rivet-trace") == "trace-123")
  }

  @Test
  func computedPropertiesPreserveCanonicalImmutableValuesAndDuplicateResolution() {
    let headers = HTTPHeaders(
      dictionaryLiteral: ("Accept", "text/plain"),
      ("ACCEPT", "application/json")
    )

    let expectedValues = ["accept": "application/json"]

    #expect(headers.accept == "application/json")
    #expect(headers.value(for: HTTPHeaderName.accept) == "application/json")
    #expect(headers.values == expectedValues)
  }

  @Test
  func headersUseLaterValueForDuplicateDictionaryLiteralKey() {
    let headers = HTTPHeaders(
      dictionaryLiteral: ("Accept", "text/plain"),
      ("Accept", "application/json")
    )

    #expect(headers.values == ["accept": "application/json"])
  }

  @Test
  func headersTreatNamesCaseInsensitively() {
    let headers = HTTPHeaders(
      dictionaryLiteral: ("Authorization", "Basic credentials"),
      ("authorization", "Bearer token")
    )

    #expect(headers.values == ["authorization": "Bearer token"])
  }

  @Test
  func retainsValidatedURLAndRequestMetadata() throws {
    let url = try HTTPURL(#require(URL(string: "https://example.com/issues")))
    let body = Data("payload".utf8)
    let headers: HTTPHeaders = ["Accept": "application/json"]

    let request = HTTPRequest(url: url, method: .post, headers: headers, body: body)

    #expect(request.url == url)
    #expect(request.method == .post)
    #expect(request.headers == headers)
    #expect(request.body == body)
  }
}
