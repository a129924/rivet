import Foundation
import RivetHTTPClient
import Testing

@Suite("Requester")
struct RequesterTests {
  @Test
  func mapsHTTPRequestToURLRequest() async throws {
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
}
