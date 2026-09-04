import Foundation
import RivetHTTPClient
import Testing

@Suite("HTTPResponse")
struct HTTPResponseTests {
  @Test
  func retainsRawTransportResponseValues() {
    let response = HTTPResponse.fixture

    #expect(response.statusCode == 200)
    #expect(response.headers == ["Content-Type": "application/json"])
    #expect(response.body == Data("{}".utf8))
  }
}
