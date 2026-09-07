import Foundation

public enum HTTPClientError: Error {
  case urlLoading(URLError)
  case nonHTTPResponse
  case unexpected(any Error)
}
