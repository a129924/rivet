import Foundation
import RivetHTTPClient

internal protocol GitHubRestClient: Sendable {
  func get(url: HTTPURL, headers: HTTPHeaders, body: Data?) async throws -> HTTPResponse
  func post(url: HTTPURL, headers: HTTPHeaders, body: Data?) async throws -> HTTPResponse
  func put(url: HTTPURL, headers: HTTPHeaders, body: Data?) async throws -> HTTPResponse
  func patch(url: HTTPURL, headers: HTTPHeaders, body: Data?) async throws -> HTTPResponse
  func executeGet(_ request: HTTPRequest) async throws -> HTTPResponse
  func executePost(_ request: HTTPRequest) async throws -> HTTPResponse
  func executePut(_ request: HTTPRequest) async throws -> HTTPResponse
  func executePatch(_ request: HTTPRequest) async throws -> HTTPResponse
}

extension GitHubRestClient {
  internal func get(
    url: HTTPURL, headers: HTTPHeaders, body: Data?
  ) async throws -> HTTPResponse {
    try await executeGet(HTTPRequest(url: url, method: .get, headers: headers, body: body))
  }

  internal func post(
    url: HTTPURL, headers: HTTPHeaders, body: Data?
  ) async throws -> HTTPResponse {
    try await executePost(HTTPRequest(url: url, method: .post, headers: headers, body: body))
  }

  internal func put(
    url: HTTPURL, headers: HTTPHeaders, body: Data?
  ) async throws -> HTTPResponse {
    try await executePut(HTTPRequest(url: url, method: .put, headers: headers, body: body))
  }

  internal func patch(
    url: HTTPURL, headers: HTTPHeaders, body: Data?
  ) async throws -> HTTPResponse {
    try await executePatch(HTTPRequest(url: url, method: .patch, headers: headers, body: body))
  }
}
