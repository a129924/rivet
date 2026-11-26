import Foundation
import GitHubIntegration
import RivetHTTPClient
import Testing

struct GitHubUnreadNotificationsSourceTests {
  @Test
  func completeEmptyListAndSinglePageSucceed() async throws {
    let empty = NotificationTransport([.success(notificationResponse())])
    let single = NotificationTransport([
      .success(notificationResponse(body: "[\(notificationJSON())]"))
    ])

    let pat = try PersonalAccessToken(rawValue: syntheticPAT)
    #expect(await makeSource(empty).list(using: pat) == .success([]))
    let outcome = await makeSource(single).list(using: pat)
    guard case .success(let threads) = outcome else {
      Issue.record("Expected a complete list")
      return
    }
    let thread = try #require(threads.first)
    #expect(threads.count == 1)
    #expect(thread.id == "opaque-1")
    #expect(thread.unread)
    #expect(thread.updatedAt == Date(timeIntervalSince1970: 1_767_225_600))
    #expect(thread.lastReadAt == nil)
    #expect(thread.subject.title == "Review this")
    #expect(thread.subject.type == "FutureSubject")
    #expect(thread.subject.url == "https://api.github.com/repos/example/rivet/issues/123")
    #expect(thread.subject.latestCommentURL == nil)
    #expect(thread.repository.id == 5_000_000_001)
    #expect(thread.repository.fullName == "example/rivet")
    #expect(await single.urls.count == 1)
  }

  @Test
  func paginatedReadPreservesOrderStateAndHeaders() async throws {
    let link =
      #"<https://api.github.com:443/notifications?page=2>; title="second, final"; rel="next last""#
    let second = notificationJSON(id: "opaque-2", unread: false)
    let third = notificationJSON(id: "opaque-3")
      .replacingOccurrences(of: #""last_read_at":null,"#, with: "")
      .replacingOccurrences(
        of: #""latest_comment_url":null"#, with: #""latest_comment_url":"opaque-link""#)
    let transport = NotificationTransport([
      .success(notificationResponse(body: "[\(notificationJSON())]", link: link)),
      .success(
        notificationResponse(
          body: "[\(second),\(third)]",
          link: "<https://api.github.com/notifications?page=1>; rel=prev")),
    ])

    let outcome = await makeSource(transport).list(
      using: try PersonalAccessToken(rawValue: syntheticPAT))
    guard case .success(let threads) = outcome else {
      Issue.record("Expected both pages")
      return
    }
    #expect(threads.map(\.id) == ["opaque-1", "opaque-2", "opaque-3"])
    #expect(threads.map(\.unread) == [true, false, true])
    #expect(threads.last?.subject.latestCommentURL == "opaque-link")
    #expect(threads.last?.lastReadAt == nil)

    let requests = await transport.requests
    #expect(
      requests.compactMap { $0.url?.absoluteString } == [
        "https://api.github.com/notifications?all=false&per_page=50",
        "https://api.github.com/notifications?all=false&per_page=50&page=2",
      ])
    for request in requests {
      #expect(request.httpMethod == "GET")
      #expect(request.httpBody == nil)
      #expect(request.value(forHTTPHeaderField: "Accept") == "application/vnd.github+json")
      #expect(request.value(forHTTPHeaderField: "User-Agent") == "Rivet")
      #expect(request.value(forHTTPHeaderField: "X-GitHub-Api-Version") == "2026-03-10")
      #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(syntheticPAT)")
    }
  }

  @Test(arguments: [
    "<http://api.github.com/notifications?page=2>; rel=next",
    "<https://other.example/notifications?page=2>; rel=next",
    "<https://api.github.com:444/notifications?page=2>; rel=next",
    "<https://user@api.github.com/notifications?page=2>; rel=next",
    "<https://api.github.com/notifications?page=2#fragment>; rel=next",
    "<https://api.github.com/notifications/threads?page=2>; rel=next",
    "<https://api.github.com/%6Eotifications?page=2>; rel=next",
    "</notifications?page=2>; rel=next",
    "<https://api.github.com/notifications?page=2&all=true>; rel=next",
    "<https://api.github.com/notifications?page=2&per_page=49>; rel=next",
    "<https://api.github.com/notifications?page=2&is_done=false>; rel=next",
    "<https://api.github.com/notifications?page=2&before=unknown>; rel=next",
    "<https://api.github.com/notifications?page=2&page=2>; rel=next",
    "<https://api.github.com/notifications?page=2&all=>; rel=next",
    "<https://api.github.com/notifications?page=1>; rel=next",
    "<https://api.github.com/notifications?page=3>; rel=next",
    "<https://api.github.com/notifications?page=2>; rel=next; anchor=\"/elsewhere\"",
    "<https://api.github.com/notifications?page=2>; rel=next; rel=prev",
    "<https://api.github.com/notifications?page=2>; rel=next, <https://api.github.com/notifications?page=2>; rel=next",
    "<https://api.github.com/notifications?page=2>; rel=last",
    "<https://api.github.com/notifications?page=2>; rel=next, <https://api.github.com/notifications?page=1>; rel=last",
    "<https://api.github.com/notifications?page=2>; rel=\"next",
    "",
  ])
  func rejectsUnverifiedLinksWithoutSendingAContinuation(link: String) async throws {
    let transport = NotificationTransport([
      .success(notificationResponse(body: "[\(notificationJSON())]", link: link))
    ])

    let result = await makeSource(transport).list(
      using: try PersonalAccessToken(rawValue: syntheticPAT))
    #expect(result == .failure(.incompletePagination))
    #expect(await transport.urls.count == 1)
  }

  @Test
  func validatedForwardLinkCanStillFailOnTheNextPage() async throws {
    let next = notificationLink(page: 2, relation: "next")
    let transport = NotificationTransport([
      .success(notificationResponse(body: "[\(notificationJSON())]", link: next)),
      .success(notificationResponse(link: notificationLink(page: 1, relation: "next"))),
    ])

    let result = await makeSource(transport).list(
      using: try PersonalAccessToken(rawValue: syntheticPAT))
    #expect(result == .failure(.incompletePagination))
    #expect(await transport.urls.count == 2)
  }

  @Test
  func missingOrMalformedPATDoesNotMakeARequest() async throws {
    let transport = NotificationTransport([])
    let source = makeSource(transport)
    #expect(await source.list(using: nil) == .failure(.accessDenied))
    let malformed = try PersonalAccessToken(rawValue: "this cannot be a Bearer header")
    #expect(await source.list(using: malformed) == .failure(.accessDenied))
    #expect(await transport.urls.isEmpty)
  }

  @Test(arguments: [
    StatusCase(code: 401, failure: .accessDenied),
    StatusCase(code: 403, failure: .accessDenied),
    StatusCase(code: 403, failure: .unavailable, headers: ["X-RateLimit-Remaining": "0"]),
    StatusCase(code: 429, failure: .unavailable),
    StatusCase(code: 304, failure: .unavailable),
    StatusCase(code: 422, failure: .unavailable),
    StatusCase(code: 503, failure: .unavailable),
    StatusCase(code: 302, failure: .unavailable, headers: ["Location": "https://other.example/"]),
  ])
  func rejectsNonSuccessStatusWithoutExposingTheResponse(input: StatusCase) async throws {
    let denied = notificationResponse(
      status: input.code, body: "{\"message\":\"\(syntheticPAT)\"}", headers: input.headers)
    let transport = NotificationTransport([.success(denied)])

    let result = await makeSource(transport).list(
      using: try PersonalAccessToken(rawValue: syntheticPAT))

    #expect(result == .failure(input.failure))
    #expect(!String(reflecting: result).contains(syntheticPAT))
    #expect(await transport.urls.count == 1)
  }

  @Test
  func laterPageFailuresDiscardPreviouslyReadThreads() async throws {
    let first = notificationResponse(
      body: "[\(notificationJSON())]", link: notificationLink(page: 2, relation: "next"))
    let failedPages: [(Result<HTTPResponse, HTTPClientError>, GitHubUnreadNotificationsFailure)] = [
      (.success(notificationResponse(status: 503)), .incompletePagination),
      (
        .success(
          notificationResponse(status: 302, headers: ["Location": "https://other.example/"])),
        .incompletePagination
      ),
      (.failure(.networkFailure(URLError(.timedOut))), .incompletePagination),
      (.success(notificationResponse(status: 401)), .accessDenied),
      (.success(notificationResponse(body: "{}")), .invalidData),
    ]
    let pat = try PersonalAccessToken(rawValue: syntheticPAT)
    for (failedPage, failure) in failedPages {
      let transport = NotificationTransport([.success(first), failedPage])
      #expect(await makeSource(transport).list(using: pat) == .failure(failure))
      #expect(await transport.urls.count == 2)
    }
  }

  @Test
  func requiredDataAndReflectedCredentialAreRejected() async throws {
    let invalidBodies = [
      notificationJSON().replacingOccurrences(of: #""id":"opaque-1","#, with: ""),
      notificationJSON().replacingOccurrences(of: "2026-01-01T00:00:00Z", with: "not-a-date"),
      notificationJSON().replacingOccurrences(of: "5000000001", with: #""invalid""#),
      notificationJSON().replacingOccurrences(of: "Review this", with: syntheticPAT),
    ]
    let pat = try PersonalAccessToken(rawValue: syntheticPAT)
    for body in invalidBodies {
      let transport = NotificationTransport([.success(notificationResponse(body: "[\(body)]"))])
      let result = await makeSource(transport).list(using: pat)
      #expect(result == .failure(.invalidData))
      #expect(!String(reflecting: result).contains(syntheticPAT))
    }
  }

  @Test
  func preCancelledCallDoesNotSendTheFirstPage() async throws {
    let transport = NotificationTransport([])
    let source = makeSource(transport)
    let pat = try PersonalAccessToken(rawValue: syntheticPAT)

    let task = Task {
      withUnsafeCurrentTask { $0?.cancel() }
      return await source.list(using: pat)
    }

    #expect(await task.value == .cancelled)
    #expect(await transport.urls.isEmpty)
  }

  @Test(arguments: [200, 401])
  func cancellationWhileWaitingForContinuationWinsOverLateResult(status: Int) async throws {
    let first = notificationResponse(link: notificationLink(page: 2, relation: "next"))
    let transport = NotificationTransport(
      [.success(first), .success(notificationResponse(status: status))], pauseSecondRequest: true)
    let pat = try PersonalAccessToken(rawValue: syntheticPAT)
    let source = makeSource(transport)
    let task = Task { await source.list(using: pat) }

    let deadline = ContinuousClock.now + .seconds(3)
    while !(await transport.isPaused), ContinuousClock.now < deadline {
      try await Task.sleep(for: .milliseconds(5))
    }
    let reachedContinuation = await transport.isPaused
    task.cancel()
    await transport.release()

    #expect(reachedContinuation)
    #expect(await task.value == .cancelled)
    #expect(await transport.urls.count == 2)
  }

  @Test
  func transportCancellationIsReportedAsCancellation() async throws {
    let transport = NotificationTransport([.failure(.cancelled(underlying: URLError(.cancelled)))])
    let result = await makeSource(transport).list(
      using: try PersonalAccessToken(rawValue: syntheticPAT))
    #expect(result == .cancelled)
  }

  struct StatusCase: Sendable {
    let code: Int
    let failure: GitHubUnreadNotificationsFailure
    var headers: [String: String] = [:]
  }

  private func makeSource(_ transport: NotificationTransport) -> GitHubUnreadNotificationsSource {
    GitHubUnreadNotificationsSource(client: HTTPClient(transport: transport))
  }
}

private let syntheticPAT = "synthetic-notifications-token-never-used-live"

private func notificationResponse(
  status: Int = 200, body: String = "[]", link: String? = nil, headers: [String: String] = [:]
) -> HTTPResponse {
  var fields = headers
  fields["Link"] = link
  return HTTPResponse(statusCode: status, headers: HTTPHeaders(fields), body: Data(body.utf8))
}

private func notificationLink(page: Int, relation: String) -> String {
  "<https://api.github.com/notifications?all=false&per_page=50&page=\(page)>; rel=\(relation)"
}

private func notificationJSON(id: String = "opaque-1", unread: Bool = true) -> String {
  """
  {"id":"\(id)","unread":\(unread),"updated_at":"2026-01-01T00:00:00Z","last_read_at":null,
   "subject":{"title":"Review this","type":"FutureSubject",
              "url":"https://api.github.com/repos/example/rivet/issues/123","latest_comment_url":null},
   "repository":{"id":5000000001,"full_name":"example/rivet"}}
  """
}

private actor NotificationTransport: Transport {
  private let script: [Result<HTTPResponse, HTTPClientError>]
  private var pauseSecondRequest: Bool
  private var pause: CheckedContinuation<Void, Never>?
  private(set) var requests: [URLRequest] = []
  var urls: [URL] { requests.compactMap(\.url) }
  var isPaused: Bool { pause != nil }

  init(_ script: [Result<HTTPResponse, HTTPClientError>], pauseSecondRequest: Bool = false) {
    self.script = script
    self.pauseSecondRequest = pauseSecondRequest
  }

  func execute(_ request: URLRequest) async throws(HTTPClientError) -> HTTPResponse {
    let index = requests.count
    requests.append(request)
    if index == 1, pauseSecondRequest {
      await withCheckedContinuation { pause = $0 }
    }
    guard script.indices.contains(index) else {
      throw .networkFailure(URLError(.badServerResponse))
    }
    return try script[index].get()
  }

  func release() {
    pauseSecondRequest = false
    pause?.resume()
    pause = nil
  }
}
