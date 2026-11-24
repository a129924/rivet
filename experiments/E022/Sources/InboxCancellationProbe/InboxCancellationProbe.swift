import Dispatch
import Foundation
import GitHubIntegration
import RivetHTTPClient
import RivetPRInbox
import RivetPRInboxGitHub

@main
struct InboxCancellationProbe {
  static func main() async throws {
    for cancel in [false, true] {
      let watchdog = DispatchWorkItem {
        FileHandle.standardError.write(Data("watchdog expired\n".utf8))
        exit(2)
      }
      DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(10), execute: watchdog)
      let observation = try await runCase(cancel: cancel)
      watchdog.cancel()
      let output = try JSONEncoder().encode(observation)
      try FileHandle.standardOutput.write(contentsOf: output + Data([10]))
    }
  }

  private static func runCase(cancel: Bool) async throws -> Observation {
    let (searchReached, signal) = AsyncStream<Void>.makeStream(bufferingPolicy: .bufferingNewest(1))
    let rest = GatedREST(searchReached: signal)
    let inbox = PRInboxFacade(selfReviewSource: GitHubSelfReviewSource(rest: rest))
    let caller = Task { await inbox.refresh() }

    var events = searchReached.makeAsyncIterator()
    guard await events.next() != nil else { throw StubError.missingSearch }
    if cancel { caller.cancel() }
    try await rest.releaseSearchResponse()
    let result = await caller.value
    let snapshot = await rest.snapshot()

    let outcome: String
    switch result {
    case .success(let items):
      let expected = InboxItem(
        owner: "fixture-owner", repository: "fixture", number: 17, title: "Fixture PR")
      outcome = items == [expected] ? "expectedCandidate" : "otherSuccess"
    case .failure(.unavailable):
      outcome = "unavailable"
    case .failure:
      outcome = "otherFailure"
    }
    return Observation(
      variant: cancel ? "cancel" : "control",
      callerCancellationRequested: caller.isCancelled,
      cancellationAtResponse: snapshot.cancelled,
      paths: snapshot.paths,
      outcome: outcome)
  }
}

private struct Observation: Encodable {
  let variant: String
  let callerCancellationRequested: Bool
  let cancellationAtResponse: Bool?
  let paths: [String]
  let outcome: String
}

private enum StubError: Error {
  case unexpectedRequest
  case missingSearch
}

private actor GatedREST: GitHubRestClient {
  private let searchReached: AsyncStream<Void>.Continuation
  private var responseGate: CheckedContinuation<Void, Never>?
  private var paths: [String] = []
  private var cancellationAtResponse: Bool?

  init(searchReached: AsyncStream<Void>.Continuation) {
    self.searchReached = searchReached
  }

  func executeGet(_ request: HTTPRequest) async throws -> HTTPResponse {
    let path = request.url.value.path
    paths.append(path)
    switch (paths.count, path) {
    case (1, "/user"):
      return response(#"{"login":"fixture-user"}"#)
    case (2, "/search/issues"):
      await withCheckedContinuation { completion in
        responseGate = completion
        searchReached.yield(())
        searchReached.finish()
      }
      cancellationAtResponse = Task.isCancelled
      // Ignore cancellation here so the Adapter receives an otherwise valid response.
      return response(
        """
        {"total_count":1,"incomplete_results":false,"items":[{
          "repository_url":"https://api.github.com/repos/fixture-owner/fixture",
          "number":17,"title":"Fixture PR","state":"open",
          "user":{"login":"fixture-user"},"pull_request":{}
        }]}
        """)
    default:
      throw StubError.unexpectedRequest
    }
  }

  func releaseSearchResponse() throws {
    guard let responseGate else { throw StubError.missingSearch }
    self.responseGate = nil
    responseGate.resume()
  }

  func snapshot() -> (paths: [String], cancelled: Bool?) {
    (paths, cancellationAtResponse)
  }

  func executePost(_ request: HTTPRequest) async throws -> HTTPResponse {
    paths.append(request.url.value.path)
    throw StubError.unexpectedRequest
  }

  func executePut(_ request: HTTPRequest) async throws -> HTTPResponse {
    paths.append(request.url.value.path)
    throw StubError.unexpectedRequest
  }

  func executePatch(_ request: HTTPRequest) async throws -> HTTPResponse {
    paths.append(request.url.value.path)
    throw StubError.unexpectedRequest
  }

  private func response(_ body: String) -> HTTPResponse {
    HTTPResponse(statusCode: 200, headers: HTTPHeaders(), body: Data(body.utf8))
  }
}
