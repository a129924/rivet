import Foundation
import RivetHTTPClient
import Testing

@testable import GitHubIntegration

private let statusCases: [(Int, GitHubAPIFailure)] = [
  (401, .unauthorized),
  (404, .notFound),
  (429, .rateLimited),
  (499, .unexpectedStatus(statusCode: 499)),
  (500, .serverError(statusCode: 500)),
  (599, .serverError(statusCode: 599)),
  (600, .unexpectedStatus(statusCode: 600)),
  (200, .unexpectedStatus(statusCode: 200)),
  (204, .unexpectedStatus(statusCode: 204)),
  (304, .unexpectedStatus(statusCode: 304)),
  (422, .unexpectedStatus(statusCode: 422)),
]

@Suite("GitHub REST response classification")
struct GitHubResponseClassifierTests {
  private let classifier = GitHubResponseClassifier()

  @Test(arguments: statusCases)
  func classifiesRejectedStatus(statusCode: Int, expected: GitHubAPIFailure) {
    #expect(classifier.classifyFailure(response(statusCode)) == expected)
  }

  @Test(
    arguments: [
      #"{"message":"Resource not accessible by integration"}"#,
      #"{"message":" RESOURCE NOT ACCESSIBLE BY PERSONAL ACCESS TOKEN. "}"#,
    ],
    [HTTPHeaders(), HTTPHeaders(["X-RateLimit-Remaining": "0"])]
  )
  func explicitPermissionDenialTakesPrecedence(body: String, headers: HTTPHeaders) {
    #expect(classifier.classifyFailure(response(headers: headers, body: body)) == .forbidden)
  }

  @Test(
    arguments: [
      #"{"message":"You have exceeded a secondary rate limit."}"#,
      #"{"message":"You have exceeded a secondary rate limit and have been temporarily blocked from content creation. Please wait."}"#,
    ],
    [
      HTTPHeaders(), HTTPHeaders(["X-RateLimit-Remaining": "7"]),
      HTTPHeaders(["X-RateLimit-Remaining": "7", "Retry-After": "invalid"]),
    ]
  )
  func explicitSecondaryRateLimitUsesMessage(body: String, headers: HTTPHeaders) {
    #expect(classifier.classifyFailure(response(headers: headers, body: body)) == .rateLimited)
  }

  @Test(
    arguments: [
      #"{"message":"Forbidden"}"#,
      #"{"message":"There is no indication that you have exceeded a secondary rate limit."}"#,
      #"{"message":"#,
      "",
    ]
  )
  func zeroRemainingIsEvidenceWhenMessageDoesNotGiveAReason(body: String) {
    let headers = HTTPHeaders(["x-RaTeLiMiT-ReMaInInG": " \t0 "])
    #expect(classifier.classifyFailure(response(headers: headers, body: body)) == .rateLimited)
  }

  @Test(arguments: ["1", "-1", "-0", "+0", "00x", "0, 1", "0.0", "", "٩", "\(Int.max)0"])
  func invalidOrPositiveRemainingIsNotEvidence(remaining: String) {
    let headers = HTTPHeaders(["X-RateLimit-Remaining": remaining])
    #expect(classifier.classifyFailure(response(headers: headers)) == .unclassifiedForbidden)
  }

  @Test(
    arguments: [
      #"{"message":"Resource not accessible by integration. You have exceeded a secondary rate limit."}"#,
      #"{"message":"You have exceeded a secondary rate limit.\nResource not accessible by integration."}"#,
    ],
    [HTTPHeaders(), HTTPHeaders(["X-RateLimit-Remaining": "0"])]
  )
  func competingExplicitReasonsRemainUnclassified(body: String, headers: HTTPHeaders) {
    #expect(
      classifier.classifyFailure(response(headers: headers, body: body)) == .unclassifiedForbidden)
  }

  @Test(
    arguments: [
      "",
      #"{"message":12}"#,
      #"{"message":"#,
      #"{"error":{"message":"Resource not accessible by integration"}}"#,
      #"{"message":"Forbidden"}"#,
      #"{"message":"The message was \"Resource not accessible by integration\"."}"#,
      #"{"message":"It is not true that you have exceeded a secondary rate limit."}"#,
    ]
  )
  func missingOrUnrecognizedMessageLeavesCauseUnknown(body: String) {
    #expect(classifier.classifyFailure(response(body: body)) == .unclassifiedForbidden)
  }

  @Test(
    arguments: [
      HTTPHeaders(["Retry-After": "60"]),
      HTTPHeaders(["Retry-After": "invalid"]),
      HTTPHeaders(["X-RateLimit-Reset": "1795533600"]),
      HTTPHeaders(["X-RateLimit-Reset": "invalid"]),
      HTTPHeaders(["Retry-After": "60", "X-RateLimit-Reset": "1795533600"]),
      HTTPHeaders(["X-Accepted-GitHub-Permissions": "contents=read"]),
    ]
  )
  func recoveryTimingAndRequiredPermissionsDoNotGiveAReason(headers: HTTPHeaders) {
    #expect(classifier.classifyFailure(response(headers: headers)) == .unclassifiedForbidden)
  }

  private func response(
    _ statusCode: Int = 403, headers: HTTPHeaders = [:], body: String = ""
  ) -> HTTPResponse {
    HTTPResponse(statusCode: statusCode, headers: headers, body: Data(body.utf8))
  }
}
