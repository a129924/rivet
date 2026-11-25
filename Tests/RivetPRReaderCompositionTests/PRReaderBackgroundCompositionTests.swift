import Foundation
import GitHubIntegration
import RivetHTTPClient
import RivetPRReader
import RivetPRReaderComposition
import Testing

@testable import RivetPRReaderPresentation

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct PRReaderBackgroundCompositionTests {
  private let client = ControlledREST()
  private let id = ReaderPullRequestID(owner: "owner", repository: "repo", number: 42)
  private let body = #"{"title":"Title","body":"Summary","user":{"login":"author"}}"#

  @Test
  func compositionUsesTheRealAdapterAndPreservesReaderFailureMapping() async throws {
    let session = makePRReaderBackgroundSession(rest: client)
    session.select(id)
    let initial = try #require(session.currentRequestCompletion())
    let request = await client.waitForRequest(1)
    #expect(request.method == .get)
    #expect(request.url.value.absoluteString == "https://api.github.com/repos/owner/repo/pulls/42")
    #expect(
      request.headers
        == HTTPHeaders([
          "Accept": "application/vnd.github+json",
          "User-Agent": "Rivet",
          "X-GitHub-Api-Version": "2026-03-10",
        ]))
    #expect(request.body == nil)

    await client.release(1, status: 200, body: body)
    await initial()
    let background = ReaderBackground(title: "Title", body: "Summary", author: "author")
    #expect(session.state == .loaded(id, background))

    session.refresh()
    let refresh = try #require(session.currentRequestCompletion())
    #expect(session.state == .refreshing(id, previous: background))
    _ = await client.waitForRequest(2)
    await client.release(2, status: 404, body: #"{"message":"Not Found"}"#)
    await refresh()
    #expect(session.state == .refreshFailed(id, previous: background, failure: .notReadable))
  }

  @Test
  func reopenGetsAnIndependentSessionWhileTheOldAdapterReturnsLate() async throws {
    let first = makePRReaderBackgroundSession(rest: client)
    first.select(id)
    let retired = try #require(first.currentRequestCompletion())
    _ = await client.waitForRequest(1)
    first.invalidate()

    let reopened = makePRReaderBackgroundSession(rest: client)
    #expect(first !== reopened)
    #expect(reopened.state == .idle)
    reopened.select(id)
    let active = try #require(reopened.currentRequestCompletion())
    _ = await client.waitForRequest(2)

    await client.release(1, status: 200, body: body)
    await retired()
    #expect(await client.cancellations[1] == true)
    #expect(first.state == .idle)
    #expect(reopened.state == .loading(id))

    await client.release(2, status: 200, body: #"{"title":"Reopened"}"#)
    await active()
    #expect(
      reopened.state == .loaded(id, ReaderBackground(title: "Reopened", body: nil, author: nil)))
    #expect(reopened.currentRequestCompletion() == nil)
  }
}

private actor ControlledREST: GitHubRestClient {
  private enum UnexpectedRequest: Error {
    case write
  }

  private var requests: [HTTPRequest] = []
  private var responders: [Int: CheckedContinuation<HTTPResponse, Never>] = [:]
  private var waiters: [Int: CheckedContinuation<HTTPRequest, Never>] = [:]
  private(set) var cancellations: [Int: Bool] = [:]

  func executeGet(_ request: HTTPRequest) async throws -> HTTPResponse {
    requests.append(request)
    let index = requests.count
    let response = await withCheckedContinuation { continuation in
      responders[index] = continuation
      waiters.removeValue(forKey: index)?.resume(returning: request)
    }
    cancellations[index] = Task.isCancelled
    return response
  }

  func executePost(_ request: HTTPRequest) async throws -> HTTPResponse {
    throw UnexpectedRequest.write
  }

  func executePut(_ request: HTTPRequest) async throws -> HTTPResponse {
    throw UnexpectedRequest.write
  }

  func executePatch(_ request: HTTPRequest) async throws -> HTTPResponse {
    throw UnexpectedRequest.write
  }

  func waitForRequest(_ index: Int) async -> HTTPRequest {
    if index <= requests.count {
      return requests[index - 1]
    }
    return await withCheckedContinuation { waiters[index] = $0 }
  }

  func release(_ index: Int, status: Int, body: String) {
    responders.removeValue(forKey: index)?.resume(
      returning: HTTPResponse(statusCode: status, headers: [:], body: Data(body.utf8))
    )
  }
}
