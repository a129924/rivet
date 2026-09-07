import Foundation
import RivetHTTPClient
import Testing

@Suite("HTTPResponse")
struct HTTPResponseTests {
  @Test
  func decodesUTF8BodyUsingDefaultEncoding() {
    let response = HTTPResponse(
      statusCode: 200,
      headers: ["Content-Type": "text/plain"],
      body: Data("Rivet".utf8)
    )

    #expect(response.text() == "Rivet")
  }

  @Test
  func decodesBodyUsingExplicitEncoding() {
    let response = HTTPResponse(
      statusCode: 200,
      headers: [:],
      body: Data([0xE9])
    )

    #expect(response.text(encoding: .isoLatin1) == "é")
  }

  @Test
  func returnsNilForBodyIncompatibleWithRequestedEncodingWithoutMutatingResponse() {
    let headers: HTTPHeaders = ["Content-Type": "application/octet-stream"]
    let body = Data([0xFF])
    let response = HTTPResponse(statusCode: 418, headers: headers, body: body)

    #expect(response.text() == nil)
    #expect(response.statusCode == 418)
    #expect(response.headers == headers)
    #expect(response.body == body)
  }

  @Test
  func retainsRawTransportResponseValues() {
    let response = HTTPResponse.fixture

    #expect(response.statusCode == 200)
    #expect(response.headers == ["Content-Type": "application/json"])
    #expect(response.body == Data("{}".utf8))
  }
}
