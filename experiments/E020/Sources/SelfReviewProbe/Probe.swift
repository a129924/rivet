import Darwin
import Foundation
import GitHubIntegration
import RivetHTTPClient
import RivetPRInbox
import RivetPRInboxGitHub

@main
struct Probe {
  private typealias Deadline = ContinuousClock.Instant

  static func main() async {
    guard CommandLine.arguments.count == 1, let input = ProbeInput.read() else {
      printReport(.init(status: .notExecuted))
      Darwin.exit(2)
    }

    let deadline = ContinuousClock.now.advanced(by: .seconds(60))
    let report = await withTaskGroup(of: ProbeReport.self) { tasks in
      tasks.addTask { await run(input, deadline: deadline) }
      tasks.addTask {
        try? await ContinuousClock().sleep(until: deadline)
        return ProbeReport(status: .timeout)
      }
      let result = await tasks.next() ?? ProbeReport(status: .timeout)
      tasks.cancelAll()
      return result
    }
    printReport(report)
    if report.status != .sampleMatched { Darwin.exit(1) }
  }

  private static func run(_ input: ProbeInput, deadline: Deadline) async -> ProbeReport {
    let provider = OAuthTokenProvider(
      store: MemoryCredential(credential: input.credential), fetcher: RefreshDisabled())
    guard let scope = try? await GitHubClientScope.prepare(provider: provider) else {
      return .init(status: .preparationUnavailable)
    }

    let rest = ProbeREST(rest: scope.rest, deadline: deadline)
    let source = GitHubSelfReviewSource(rest: rest)
    let outcome = await PRInboxFacade(selfReviewSource: source).refresh()
    guard ContinuousClock.now < deadline else { return .init(status: .timeout) }

    let accountMatched = await rest.accountMatched
    let count = await rest.getCount
    if accountMatched == false {
      return .init(status: .accountMismatch, getCount: count, accountMatched: false)
    }
    guard case .success(let items) = outcome, accountMatched == true else {
      return .init(status: .inboxUnavailable, getCount: count, accountMatched: accountMatched)
    }

    let sample = InboxItem(
      owner: "a129924", repository: "mlops-async", number: 72, title: input.title)
    let matches = items.contains(sample)
    return .init(
      status: matches ? .sampleMatched : .sampleMismatch,
      getCount: count, accountMatched: true, queueCount: items.count, fieldsMatch: matches)
  }

  private static func printReport(_ report: ProbeReport) {
    guard let data = try? JSONEncoder().encode(report) else { return }
    guard let line = String(bytes: data, encoding: .utf8) else { return }
    print(line)
  }
}

private struct ProbeReport: Encodable, Sendable {
  enum Status: String, Encodable, Sendable {
    case notExecuted, preparationUnavailable, accountMismatch, inboxUnavailable
    case timeout, sampleMatched, sampleMismatch
  }

  let status: Status
  var getCount: Int?
  var accountMatched: Bool?
  var queueCount: Int?
  var fieldsMatch: Bool?
}

private actor ProbeREST: GitHubRestClient {
  private struct Viewer: Decodable, Sendable {
    let login: String
  }

  let rest: any GitHubRestClient
  let deadline: ContinuousClock.Instant
  private(set) var getCount = 0
  private(set) var accountMatched: Bool?

  init(rest: any GitHubRestClient, deadline: ContinuousClock.Instant) {
    self.rest = rest
    self.deadline = deadline
  }

  func executeGet(_ request: HTTPRequest) async throws -> HTTPResponse {
    try Task.checkCancellation()
    let url = request.url.value
    guard ContinuousClock.now < deadline, getCount < 11, request.method == .get,
      url.scheme == "https", url.host == "api.github.com",
      url.path == (getCount == 0 ? "/user" : "/search/issues")
    else { throw ProbeError.rejected }

    getCount += 1
    let response = try await rest.executeGet(request)
    if url.path == "/user", response.statusCode == 200 {
      let viewer = try response.json(Viewer.self, decoder: JSONDecoder())
      accountMatched = viewer.login.caseInsensitiveCompare("a129924") == .orderedSame
      guard accountMatched == true else { throw ProbeError.rejected }
    }
    return response
  }

  func executePost(_ request: HTTPRequest) async throws -> HTTPResponse {
    throw ProbeError.rejected
  }

  func executePut(_ request: HTTPRequest) async throws -> HTTPResponse {
    throw ProbeError.rejected
  }

  func executePatch(_ request: HTTPRequest) async throws -> HTTPResponse {
    throw ProbeError.rejected
  }
}

private enum ProbeError: Error, Sendable {
  case rejected
}

private struct MemoryCredential: OAuthCredentialStore {
  let credential: GitHubOAuthCredentialBundle

  func load() async throws(any Error & Sendable) -> GitHubOAuthCredentialBundle? {
    credential
  }

  func save(_ credential: GitHubOAuthCredentialBundle) async throws(any Error & Sendable) {
    throw ProbeError.rejected
  }
}

private struct RefreshDisabled: OAuthTokenFetcher {
  func refresh(
    _ credential: GitHubOAuthCredentialBundle
  ) async throws(OAuthTokenRefreshError) -> GitHubOAuthCredentialBundle {
    throw .credentialRejected
  }
}

private struct ProbeInput: Sendable {
  let title: String
  let credential: GitHubOAuthCredentialBundle

  static func read() -> Self? {
    guard readHidden("已核對 mlops-async#72 仍開啟且作者為 a129924？輸入 yes：") == "yes",
      let title = readHidden("PR #72 的完整標題："), !title.isEmpty,
      let accessToken = readHidden("既有 OAuth access token："), isToken(accessToken),
      let refreshToken = readHidden("既有 OAuth refresh token："), isToken(refreshToken),
      let accessExpiry = readHidden("Access token 到期時間（RFC 3339）："),
      let refreshExpiry = readHidden("Refresh token 到期時間（RFC 3339）："),
      let accessDate = expirationDate(accessExpiry),
      let refreshDate = expirationDate(refreshExpiry),
      accessDate > Date(), refreshDate > Date(),
      let scopes = readHidden("OAuth scopes（可空白）：")
    else { return nil }

    return Self(
      title: title,
      credential: GitHubOAuthCredentialBundle(
        accessToken: GitHubAccessToken(rawValue: accessToken),
        refreshToken: GitHubOAuthRefreshToken(rawValue: refreshToken),
        accessTokenExpiresAt: accessDate, refreshTokenExpiresAt: refreshDate,
        tokenType: .bearer, grantedScopes: scopes))
  }

  private static func expirationDate(_ value: String) -> Date? {
    let parser = ISO8601DateFormatter()
    if let date = parser.date(from: value) { return date }
    parser.formatOptions.insert(.withFractionalSeconds)
    return parser.date(from: value)
  }

  private static func isToken(_ value: String) -> Bool {
    !value.isEmpty && value.utf8.allSatisfy { (33...126).contains($0) }
  }

  private static func readHidden(_ prompt: String) -> String? {
    var buffer = [CChar](repeating: 0, count: 4_096)
    return buffer.withUnsafeMutableBufferPointer { buffer in
      guard let start = buffer.baseAddress else { return nil }
      defer { start.update(repeating: 0, count: buffer.count) }
      guard readpassphrase(prompt, start, buffer.count, RPP_REQUIRE_TTY) != nil,
        buffer[buffer.count - 2] == 0
      else { return nil }
      return String(validatingCString: start)
    }
  }
}
