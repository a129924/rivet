import Foundation
import RivetHTTPClient
import Testing

@Suite("HTTPRequest")
struct HTTPRequestTests {
  @Test
  func exposesTypedStandardHeaderNamesWithCanonicalRawValues() {
    #expect(HTTPHeaderName.accept.rawValue == "accept")
    #expect(HTTPHeaderName.authorization.rawValue == "authorization")
    #expect(HTTPHeaderName.contentType.rawValue == "content-type")
    #expect(HTTPHeaderName.userAgent.rawValue == "user-agent")
    #expect(HTTPHeaderName.etag.rawValue == "etag")
    #expect(HTTPHeaderName.ifNoneMatch.rawValue == "if-none-match")
    #expect(HTTPHeaderName.location.rawValue == "location")
    #expect(HTTPHeaderName.link.rawValue == "link")
    #expect(HTTPHeaderName.retryAfter.rawValue == "retry-after")
  }

  @Test
  func readsStandardHeadersUsingComputedProperties() {
    let headers: HTTPHeaders = [
      .accept: "application/json",
      .authorization: "Bearer token",
      .contentType: "application/json; charset=utf-8",
      .userAgent: "Rivet",
      .etag: "tag-value",
      .ifNoneMatch: "prior-tag",
      .location: "https://example.com/redirect",
      .link: "<https://example.com/page>; rel=next",
      .retryAfter: "30",
    ]

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
    let headers: HTTPHeaders = [
      .contentType: "application/json",
      .custom("X-Rivet-Trace"): "trace-123",
    ]

    #expect(headers.value(for: "CONTENT-TYPE") == "application/json")
    #expect(headers.value(for: HTTPHeaderName.contentType) == "application/json")
    #expect(headers.value(for: "x-rivet-trace") == "trace-123")
    #expect(headers.value(for: .custom("x-rivet-trace")) == "trace-123")
  }

  @Test
  func typedDictionaryLiteralPreservesCanonicalValuesAndDuplicateResolution() {
    let headers: HTTPHeaders = [
      .accept: "text/plain",
      .custom("ACCEPT"): "application/json",
    ]

    let expectedValues = ["accept": "application/json"]

    #expect(headers.accept == "application/json")
    #expect(headers.value(for: HTTPHeaderName.accept) == "application/json")
    #expect(headers.values == expectedValues)
  }

  @Test
  func headersUseLaterValueForDuplicateTypedDictionaryLiteralKey() {
    let headers: HTTPHeaders = [
      .custom("Accept"): "text/plain",
      .accept: "application/json",
    ]

    #expect(headers.values == ["accept": "application/json"])
  }

  @Test
  func dynamicStringInitializerTreatsNamesCaseInsensitively() {
    let headers = HTTPHeaders([
      "Authorization": "Basic credentials",
      "authorization": "Bearer token",
    ])

    #expect(headers.values == ["authorization": "Bearer token"])
  }

  @Test
  func typedSubscriptAndStandardPropertiesWriteAndRemoveHeaders() {
    var headers: HTTPHeaders = [
      .accept: "text/plain",
      .custom("X-Rivet-Trace"): "trace-123",
    ]

    headers[.accept] = "application/json"
    headers.authorization = "Bearer token"
    headers[.custom("x-rivet-trace")] = "trace-456"

    #expect(headers[.accept] == "application/json")
    #expect(headers.authorization == "Bearer token")
    #expect(headers[.custom("X-RIVET-TRACE")] == "trace-456")

    headers.authorization = nil
    headers[.custom("X-Rivet-Trace")] = nil

    #expect(headers.authorization == nil)
    #expect(headers[.custom("x-rivet-trace")] == nil)
    #expect(headers.accept == "application/json")
  }

  @Test
  func allStandardPropertiesWriteAndRemoveTheirHeaders() {
    var headers = HTTPHeaders()

    headers.accept = "application/json"
    headers.authorization = "Bearer token"
    headers.contentType = "application/json"
    headers.userAgent = "Rivet"
    headers.etag = "tag-value"
    headers.ifNoneMatch = "prior-tag"
    headers.location = "https://example.com/redirect"
    headers.link = "<https://example.com/page>; rel=next"
    headers.retryAfter = "30"

    #expect(headers.values.count == 9)

    headers.accept = nil
    headers.authorization = nil
    headers.contentType = nil
    headers.userAgent = nil
    headers.etag = nil
    headers.ifNoneMatch = nil
    headers.location = nil
    headers.link = nil
    headers.retryAfter = nil

    #expect(headers.values.isEmpty)
  }

  @Test
  func dynamicStringInitializerInteroperatesWithTypedMutationAndValueSemantics() {
    var headers = HTTPHeaders(["Content-Type": "text/plain"])
    var copy = headers

    headers[.contentType] = "application/json"
    copy.contentType = nil

    #expect(headers.value(for: .contentType) == "application/json")
    #expect(copy.value(for: "content-type") == nil)
  }

  @Test
  func retainsValidatedURLAndRequestMetadata() throws {
    let url = try HTTPURL(#require(URL(string: "https://example.com/issues")))
    let body = Data("payload".utf8)
    let headers: HTTPHeaders = [.accept: "application/json"]

    let request = HTTPRequest(url: url, method: .post, headers: headers, body: body)

    #expect(request.url == url)
    #expect(request.method == .post)
    #expect(request.headers == headers)
    #expect(request.body == body)
  }
}
