import Foundation
import Testing
import RivetHTTPClient

@Suite("HTTPRequest")
struct HTTPRequestTests {
    @Test
    func headersUseLaterValueForDuplicateDictionaryLiteralKey() {
        let headers = HTTPHeaders(
            dictionaryLiteral: ("Accept", "text/plain"),
            ("Accept", "application/json")
        )

        #expect(headers.values == ["Accept": "application/json"])
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
