import Foundation
import RivetHTTPClient

enum InboxFixture: String, CaseIterable, Identifiable {
  case candidates, reordered, removed, empty, failure
  case pageFailure = "page-failure"

  var id: Self { self }

  var label: String {
    switch self {
    case .candidates: "候選清單"
    case .reordered: "重排並改標題"
    case .removed: "移除已選 PR"
    case .empty: "空清單"
    case .failure: "查詢失敗"
    case .pageFailure: "第二頁失敗"
    }
  }
}

struct FixtureREST: InboxReadOnlyREST {
  private static let viewer = "sample"
  private static let core = FixtureItem(repository: "core", number: 42, title: "整理 Inbox 重新整理狀態")
  private static let uiPullRequest = FixtureItem(
    repository: "ui", number: 42, title: "保留原生清單選取", draft: true)
  private static let runtime = FixtureItem(repository: "runtime", number: 17, title: "整理啟動時的連線還原")
  private static let partial = FixtureItem(repository: "partial", number: 91, title: "只存在於第一頁")

  let fixture: InboxFixture
  var onSecondPage: @Sendable () async -> Void = {}

  func executeGet(_ request: HTTPRequest) async throws -> HTTPResponse {
    let url = request.url.value
    guard url.scheme == "https", url.host == "api.github.com" else {
      throw InboxRESTError.unexpectedRequest
    }

    switch url.path {
    case "/user":
      return try Self.response(FixtureItem.User(login: Self.viewer))
    case "/search/issues":
      return try await search(url)
    default:
      throw InboxRESTError.unexpectedRequest
    }
  }

  private func search(_ url: URL) async throws -> HTTPResponse {
    let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    let page = components?.queryItems?.first { $0.name == "page" }?.value
    if page == "2", fixture == .pageFailure {
      await onSecondPage()
      return Self.failure
    }
    guard page == nil else { throw InboxRESTError.unexpectedRequest }

    switch fixture {
    case .candidates:
      return try Self.page([
        Self.core,
        FixtureItem(repository: "other", number: 5, title: "他人的 PR", author: "other-user"),
        Self.uiPullRequest,
        FixtureItem(repository: "closed", number: 6, title: "已關閉的 PR", state: "closed"),
        Self.runtime,
      ])
    case .reordered:
      let renamed = FixtureItem(
        repository: "ui", number: 42, title: "重新整理後保留原生清單選取", draft: true)
      return try Self.page([Self.core, Self.runtime, renamed])
    case .removed:
      return try Self.page([Self.core, Self.runtime])
    case .empty:
      return try Self.page([])
    case .failure:
      return Self.failure
    case .pageFailure:
      guard var next = components, let items = next.queryItems else {
        throw InboxRESTError.unexpectedRequest
      }
      next.queryItems = items + [URLQueryItem(name: "page", value: "2")]
      guard let nextURL = next.url else { throw InboxRESTError.unexpectedRequest }
      return try Self.page(
        [Self.partial], total: 2, headers: HTTPHeaders(["Link": "<\(nextURL)>; rel=\"next\""]))
    }
  }

  private static var failure: HTTPResponse {
    HTTPResponse(statusCode: 503, headers: HTTPHeaders(), body: Data())
  }

  private static func page(
    _ items: [FixtureItem], total: Int? = nil, headers: HTTPHeaders = HTTPHeaders()
  ) throws -> HTTPResponse {
    try response(FixturePage(items: items, total: total ?? items.count), headers: headers)
  }

  private static func response(
    _ payload: some Encodable, headers: HTTPHeaders = HTTPHeaders()
  ) throws -> HTTPResponse {
    HTTPResponse(statusCode: 200, headers: headers, body: try JSONEncoder().encode(payload))
  }
}

private struct FixturePage: Encodable {
  let items: [FixtureItem]
  let total: Int
  let incomplete = false

  enum CodingKeys: String, CodingKey {
    case items
    case total = "total_count"
    case incomplete = "incomplete_results"
  }
}

private struct FixtureItem: Encodable {
  struct User: Encodable {
    let login: String
  }

  let repositoryURL: String
  let number: Int
  let title: String
  let user: User
  let state: String
  let draft: Bool
  let pullRequest: [String: String] = [:]

  init(
    repository: String, number: Int, title: String, author: String = "sample",
    state: String = "open", draft: Bool = false
  ) {
    repositoryURL = "https://api.github.com/repos/sample/\(repository)"
    self.number = number
    self.title = title
    user = User(login: author)
    self.state = state
    self.draft = draft
  }

  enum CodingKeys: String, CodingKey {
    case number, title, user, state, draft
    case repositoryURL = "repository_url"
    case pullRequest = "pull_request"
  }
}
