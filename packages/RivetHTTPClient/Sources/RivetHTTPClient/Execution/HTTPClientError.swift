import Foundation

public enum HTTPClientError: Error {
  case cancelled(underlying: any Error)
  case networkFailure(URLError)
  case nonHTTPResponse
  case underlyingFailure(any Error)
}
