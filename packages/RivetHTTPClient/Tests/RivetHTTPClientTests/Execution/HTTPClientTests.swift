import Foundation
import Testing
import RivetHTTPClient

@Suite("HTTPClient")
struct HTTPClientTests {
    @Test
    func forwardsToTransportAndReturnsRawResponse() async throws {
        let captured = LockedBox<URLRequest?>(nil)
        let expected = HTTPResponse.fixture
        let transport = CapturingTransport(captured: captured, response: expected)
        let client = HTTPClient(transport: transport)
        let url = try HTTPURL(#require(URL(string: "https://example.com")))

        let response = try await client.execute(HTTPRequest(url: url, method: .get))

        #expect(captured.value?.url == url.value)
        #expect(response == expected)
    }

    @Test
    func forwardsTransportErrorWithoutMapping() async throws {
        let client = HTTPClient(transport: FailingTransport())
        let url = try HTTPURL(#require(URL(string: "https://example.com")))

        await #expect(throws: TransportFailure.unavailable) {
            try await client.execute(HTTPRequest(url: url, method: .get))
        }
    }
}
