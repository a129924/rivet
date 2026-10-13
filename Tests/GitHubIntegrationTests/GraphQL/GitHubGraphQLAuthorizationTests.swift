import Apollo
import Foundation
import Testing

@testable import GitHubIntegration

@Suite("GraphQL Bearer authorization")
struct GitHubGraphQLAuthorizationTests {
  @Test(arguments: ["token-123", "AZaz09-._~+/", "a", "a=", "a==", "a===", "a========"])
  func preservesRequestAndPropagatesDownstreamError(token: String) async throws {
    var request = URLRequest(url: try #require(URL(string: "https://example.com/graphql")))
    request.httpMethod = "POST"
    request.httpBody = Data("payload".utf8)
    request.timeoutInterval = 17
    request.cachePolicy = .reloadIgnoringLocalCacheData
    request.allHTTPHeaderFields = ["aUtHoRiZaTiOn": "Basic old", "X-Trace": "keep"]
    let original = request
    let probe = AuthorizationProbe()
    await #expect(throws: GraphQLTestFailure.expected) {
      try await GitHubGraphQLHTTPInterceptor.$accessToken.withValue(.init(rawValue: token)) {
        _ = try await GitHubGraphQLHTTPInterceptor().intercept(request: original) { result in
          await probe.record(result)
          throw GraphQLTestFailure.expected
        }
      }
    }
    let result = try #require(await probe.requests.first)
    #expect(result.value(forHTTPHeaderField: "Authorization") == "Bearer \(token)")
    #expect(result.value(forHTTPHeaderField: "X-Trace") == "keep")
    #expect(
      result.allHTTPHeaderFields?.keys.filter { $0.lowercased() == "authorization" }.count == 1)
    #expect(result.url == original.url)
    #expect(result.httpMethod == original.httpMethod)
    #expect(result.httpBody == original.httpBody)
    #expect(result.timeoutInterval == original.timeoutInterval)
    #expect(result.cachePolicy == original.cachePolicy)
    await #expect(throws: GraphQLTestFailure.expected) {
      try await GitHubGraphQLHTTPInterceptor.$accessToken.withValue(.init(rawValue: token)) {
        _ = try await GitHubGraphQLHTTPInterceptor().intercept(request: result) { repeated in
          await probe.record(repeated)
          throw GraphQLTestFailure.expected
        }
      }
    }
    #expect(await probe.requests.last == result)
    #expect(request == original)
  }

  @Test(arguments: [
    "", "=", "===", "=abc", "a=b", "a==b", " a", "a ", "a b", "a\tb",
    "a\r", "a\n", "a\r\nInjected: value", "a\0b", "é", "a😀", "a:", "a@", "a%", "a\\b", "a?",
  ])
  func invalidTokenDoesNotCallNext(token: String) async throws {
    let request = URLRequest(url: try #require(URL(string: "https://example.com/graphql")))
    let probe = AuthorizationProbe()
    let error = await #expect(throws: GitHubGraphQLClientError.invalidAuthorizationToken) {
      try await GitHubGraphQLHTTPInterceptor.$accessToken.withValue(.init(rawValue: token)) {
        _ = try await GitHubGraphQLHTTPInterceptor().intercept(request: request) { result in
          await probe.record(result)
          throw GraphQLTestFailure.expected
        }
      }
    }
    #expect(await probe.requests.isEmpty)
    if let error {
      #expect(String(describing: error) == "invalidAuthorizationToken")
      #expect(Mirror(reflecting: error).children.isEmpty)
    }
  }
}

private actor AuthorizationProbe {
  private(set) var requests: [URLRequest] = []
  func record(_ request: URLRequest) { requests.append(request) }
}
