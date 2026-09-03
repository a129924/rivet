import Foundation
import Testing
import RivetHTTPClient

@Suite("RivetHTTPClient")
struct RivetHTTPClientTests {
    @Test(arguments: ["http://example.com", "https://example.com/path"])
    func httpURLAcceptsHTTPSchemes(value: String) throws {
        let url = try #require(URL(string: value))

        let httpURL = try HTTPURL(url)

        #expect(httpURL.value == url)
    }

    @Test(arguments: ["ftp://example.com", "file:///tmp/example"])
    func httpURLRejectsUnsupportedScheme(value: String) throws {
        let url = try #require(URL(string: value))

        #expect(throws: HTTPURLValidationError.unsupportedScheme(url.scheme)) {
            try HTTPURL(url)
        }
    }

    @Test
    func httpURLRejectsMissingHost() throws {
        let url = try #require(URL(string: "https:///path"))

        #expect(throws: HTTPURLValidationError.missingHost) {
            try HTTPURL(url)
        }
    }

    @Test
    func requesterMapsHTTPRequestToURLRequest() async throws {
        let captured = LockedBox<URLRequest?>(nil)
        let transport = CapturingTransport(captured: captured, response: .fixture)
        let requester = Requester(transport: transport)
        let url = try HTTPURL(#require(URL(string: "https://example.com/issues?state=open")))
        let body = Data("payload".utf8)
        let request = HTTPRequest(
            url: url,
            method: .post,
            headers: ["Accept": "application/json", "X-Request-ID": "123"],
            body: body
        )

        _ = try await requester.execute(request)

        let mapped = try #require(captured.value)
        #expect(mapped.url == url.value)
        #expect(mapped.httpMethod == HTTPMethod.post.rawValue)
        #expect(mapped.value(forHTTPHeaderField: "Accept") == "application/json")
        #expect(mapped.value(forHTTPHeaderField: "X-Request-ID") == "123")
        #expect(mapped.httpBody == body)
    }

    @Test
    func httpClientForwardsToTransportAndReturnsRawResponse() async throws {
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
    func httpClientForwardsTransportErrorWithoutMapping() async throws {
        let client = HTTPClient(transport: FailingTransport())
        let url = try HTTPURL(#require(URL(string: "https://example.com")))

        await #expect(throws: TransportFailure.unavailable) {
            try await client.execute(HTTPRequest(url: url, method: .get))
        }
    }
}

private extension HTTPResponse {
    static let fixture = HTTPResponse(
        statusCode: 200,
        headers: ["Content-Type": "application/json"],
        body: Data("{}".utf8)
    )
}

private final class LockedBox<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: Value

    init(_ value: Value) {
        storage = value
    }

    var value: Value {
        lock.withLock { storage }
    }

    func set(_ value: Value) {
        lock.withLock { storage = value }
    }
}

private struct CapturingTransport: Transport {
    let captured: LockedBox<URLRequest?>
    let response: HTTPResponse

    func execute(_ request: URLRequest) async throws -> HTTPResponse {
        captured.set(request)
        return response
    }
}

private struct FailingTransport: Transport {
    func execute(_ request: URLRequest) async throws -> HTTPResponse {
        throw TransportFailure.unavailable
    }
}

private enum TransportFailure: Error, Equatable {
    case unavailable
}
