import Foundation
import RivetHTTPClient

enum InboxI3Fixture: String, CaseIterable, Identifiable {
  case candidates, reordered, missingTime, removed, empty, failure, pageFailure

  var id: Self { self }

  var label: String {
    switch self {
    case .candidates: "有效與缺失時間"
    case .reordered: "第二頁成功、重排更新"
    case .missingTime: "移除已選 PR 的時間"
    case .removed: "移除已選 PR"
    case .empty: "空清單"
    case .failure: "查詢失敗"
    case .pageFailure: "第二頁失敗"
    }
  }

  var isPaginated: Bool { self == .reordered || self == .pageFailure }
}

struct InboxI3FixtureREST: InboxI3ReadOnlyREST {
  let fixture: InboxI3Fixture
  var onSecondPage: @Sendable () async -> Void = {}

  func executeGet(_ request: HTTPRequest) async throws -> HTTPResponse {
    let url = request.url.value
    guard url.scheme == "https", url.host == "api.github.com" else {
      throw InboxI3RESTError.unexpectedRequest
    }
    switch url.path {
    case "/user":
      return try success(["login": "sample"])
    case "/search/issues":
      return try await search(url)
    default:
      throw InboxI3RESTError.unexpectedRequest
    }
  }

  private func search(_ url: URL) async throws -> HTTPResponse {
    guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false),
      let query = components.queryItems
    else { throw InboxI3RESTError.unexpectedRequest }

    if query.contains(URLQueryItem(name: "page", value: "2")), fixture.isPaginated {
      await onSecondPage()
      return fixture == .pageFailure
        ? unavailable : try page([ui(time: "2026-11-27T11:00:00Z")], total: 3)
    }
    guard !query.contains(where: { $0.name == "page" }) else {
      throw InboxI3RESTError.unexpectedRequest
    }

    let core = item("core", 42, "核對查詢回傳順序", time: "2026-11-27T09:00:00Z")
    let missing = item("missing", 17, "缺少更新時間")
    switch fixture {
    case .candidates:
      return try page([
        core,
        ui(time: "2026-11-27T10:00:00Z"),
        missing,
        item("null", 18, "更新時間為 null", time: NSNull()),
        item("type", 19, "更新時間型別不符", time: 42),
        item("invalid", 20, "更新時間無法解析", time: "invalid-date"),
      ])
    case .missingTime:
      return try page([core, missing, ui(time: nil)])
    case .removed:
      return try page([core, missing])
    case .empty:
      return try page([])
    case .failure:
      return unavailable
    case .reordered, .pageFailure:
      components.queryItems = query + [URLQueryItem(name: "page", value: "2")]
      guard let next = components.url else { throw InboxI3RESTError.unexpectedRequest }
      let firstPage =
        fixture == .reordered ? [core, missing] : [ui(time: "2026-11-27T11:30:00Z")]
      return try page(
        firstPage, total: firstPage.count + 1,
        headers: HTTPHeaders(["Link": "<\(next)>; rel=\"next\""]))
    }
  }

  private var unavailable: HTTPResponse {
    HTTPResponse(statusCode: 503, headers: HTTPHeaders(), body: Data())
  }

  private func ui(time: String?) -> [String: Any] {
    item("ui", 42, "保留原生清單選取", time: time)
  }

  private func item(
    _ repository: String, _ number: Int, _ title: String, time: Any? = nil
  ) -> [String: Any] {
    var item: [String: Any] = [
      "repository_url": "https://api.github.com/repos/sample/\(repository)",
      "number": number,
      "title": title,
      "state": "open",
      "user": ["login": "sample"],
      "pull_request": [String: String](),
    ]
    item["updated_at"] = time
    return item
  }

  private func page(
    _ items: [[String: Any]], total: Int? = nil, headers: HTTPHeaders = HTTPHeaders()
  ) throws -> HTTPResponse {
    try success(
      [
        "items": items, "total_count": total ?? items.count, "incomplete_results": false,
      ], headers: headers)
  }

  private func success(
    _ payload: [String: Any], headers: HTTPHeaders = HTTPHeaders()
  ) throws -> HTTPResponse {
    HTTPResponse(
      statusCode: 200, headers: headers, body: try JSONSerialization.data(withJSONObject: payload))
  }
}
