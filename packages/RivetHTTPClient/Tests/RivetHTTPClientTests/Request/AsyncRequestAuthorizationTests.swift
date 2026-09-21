import Foundation
import RivetHTTPClient
import Testing

@Suite("AsyncRequestAuthorization")
struct AsyncRequestAuthorizationTests {
  @Test
  func appliesTransformationThroughTheAsyncRequestAuthorizationExistential() async throws {
    let request = HTTPRequest(
      url: try HTTPURL(#require(URL(string: "https://example.com/issues"))),
      method: .get
    )
    let authorization: any AsyncRequestAuthorization = TestAsyncRequestAuthorization()

    let transformedRequest = try await authorization.applying(to: request)

    #expect(transformedRequest.headers.value(for: "x-test-authorization") == "applied")
  }

  @Test
  func preservesTransformationFailureThroughTheAsyncRequestAuthorizationExistential() async throws {
    let request = HTTPRequest(
      url: try HTTPURL(#require(URL(string: "https://example.com/issues"))),
      method: .get
    )
    let expectedError = TestAsyncRequestAuthorizationError.transformationFailed
    let authorization: any AsyncRequestAuthorization = FailingAsyncRequestAuthorization(
      error: expectedError
    )

    do {
      _ = try await authorization.applying(to: request)
      Issue.record("Expected the authorization transformation to fail.")
    } catch let receivedError as TestAsyncRequestAuthorizationError {
      #expect(receivedError == expectedError)
    } catch {
      Issue.record("Expected the original transformation error, got \(error).")
    }
  }
}

private struct TestAsyncRequestAuthorization: AsyncRequestAuthorization {
  func applying(to request: HTTPRequest) async throws -> HTTPRequest {
    HTTPRequest(
      url: request.url,
      method: request.method,
      headers: [.custom("X-Test-Authorization"): "applied"],
      body: request.body
    )
  }
}

private struct FailingAsyncRequestAuthorization: AsyncRequestAuthorization {
  let error: TestAsyncRequestAuthorizationError

  func applying(to request: HTTPRequest) async throws -> HTTPRequest {
    throw error
  }
}

private enum TestAsyncRequestAuthorizationError: Error, Sendable, Equatable {
  case transformationFailed
}
