import Foundation

public enum HTTPClientError: Error {
  case cancelled(underlying: any Error)
  case networkFailure(URLError)
  case nonHTTPResponse(response: URLResponse, body: Data)
  case underlyingFailure(any Error)
}
