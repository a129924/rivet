import Foundation
import RivetHTTPClient
import Testing

@Suite("HTTPRequest")
struct HTTPRequestTests {
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
