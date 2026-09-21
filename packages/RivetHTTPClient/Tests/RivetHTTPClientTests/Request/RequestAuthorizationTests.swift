import Foundation
import RivetHTTPClient
import Testing

@Suite("RequestAuthorization")
struct RequestAuthorizationTests {
  @Test
  func appliesTransformationThroughTheRequestAuthorizationExistential() throws {
    let request = HTTPRequest(
      url: try HTTPURL(#require(URL(string: "https://example.com/issues"))),
      method: .get
    )
    let authorization: any RequestAuthorization = TestRequestAuthorization()

    let transformedRequest = authorization.applying(to: request)

    #expect(transformedRequest.headers.value(for: "x-test-authorization") == "applied")
  }
}

private struct TestRequestAuthorization: RequestAuthorization {
  func applying(to request: HTTPRequest) -> HTTPRequest {
    HTTPRequest(
      url: request.url,
      method: request.method,
      headers: [.custom("X-Test-Authorization"): "applied"],
      body: request.body
    )
  }
}
