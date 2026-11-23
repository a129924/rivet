import Darwin
import Foundation
import GitHubIntegration
import InboxSearch
import RivetHTTPClient
import RivetPRInbox

@main
struct InboxProbe {
  private typealias Deadline = ContinuousClock.Instant

  static func main() async {
    guard CommandLine.arguments.count == 1, let input = ProbeInput.read() else {
      emit(ProbeReport(status: .notExecuted))
      Darwin.exit(2)
    }

    let deadline = ContinuousClock.now.advanced(by: .seconds(60))
    let report = await withTaskGroup(of: ProbeReport.self) { tasks in
      tasks.addTask { await compare(input, deadline: deadline) }
      tasks.addTask {
        try? await ContinuousClock().sleep(until: deadline)
        return ProbeReport(status: .timeout)
      }
      let first = await tasks.next() ?? ProbeReport(status: .timeout)
      tasks.cancelAll()
      return first
    }
    emit(report)
    if report.status != .sampleMatched { Darwin.exit(1) }
  }

  private static func compare(_ input: ProbeInput, deadline: Deadline) async -> ProbeReport {
    let provider = OAuthTokenProvider(
      store: ProbeCredentialStore(credential: input.credential),
      fetcher: DisabledTokenFetcher())
    let scope: GitHubClientScope
    do {
      scope = try await GitHubClientScope.prepare(provider: provider)
    } catch {
      return ProbeReport(status: .preparationUnavailable)
    }

    guard ContinuousClock.now < deadline else { return ProbeReport(status: .timeout) }
    guard let accountURL = URL(string: "https://api.github.com/user") else {
      return ProbeReport(status: .preparationUnavailable)
    }
    do {
      try Task.checkCancellation()
      let account = try await scope.rest.get(
        url: HTTPURL(accountURL),
        headers: GitHubReviewRequestSource.headers, body: nil)
      guard account.statusCode == 200 else {
        return ProbeReport(status: .accountUnavailable)
      }
      let login = try account.json(Viewer.self, decoder: JSONDecoder()).login
      guard login.caseInsensitiveCompare(input.login) == .orderedSame else {
        return ProbeReport(status: .accountMismatch)
      }
    } catch {
      return ProbeReport(status: .accountUnavailable)
    }

    let facade = PRInboxFacade(
      source: GitHubReviewRequestSource(rest: scope.rest, deadline: deadline))
    let outcome = await facade.refresh()
    guard ContinuousClock.now < deadline else { return ProbeReport(status: .timeout) }
    guard case .success(let items) = outcome else {
      return ProbeReport(status: .searchUnavailable)
    }
    let found = items.contains(where: input.positive.matches)
    let fieldsMatch = items.contains { item in
      item.owner == input.positive.owner && item.repository == input.positive.repository
        && item.number == input.positive.number && item.title == input.title
    }
    let negativesExcluded = input.negatives.allSatisfy { sample in
      !items.contains(where: sample.matches)
    }
    return ProbeReport(
      status: fieldsMatch && negativesExcluded ? .sampleMatched : .sampleMismatch,
      queueCount: items.count, positiveFound: found, fieldsMatch: fieldsMatch,
      negativeCount: input.negatives.count, negativesExcluded: negativesExcluded)
  }

  private static func emit(_ report: ProbeReport) {
    let encoded = try? JSONEncoder().encode(report)
    if let encoded, let line = String(bytes: encoded, encoding: .utf8) {
      print(line)
    }
  }
}

private struct ProbeReport: Encodable, Sendable {
  enum Status: String, Encodable, Sendable {
    case notExecuted, preparationUnavailable, accountUnavailable, accountMismatch
    case searchUnavailable, timeout, sampleMatched, sampleMismatch
  }

  let status: Status
  var queueCount: Int?
  var positiveFound: Bool?
  var fieldsMatch: Bool?
  var negativeCount: Int?
  var negativesExcluded: Bool?
}

private struct Viewer: Decodable, Sendable {
  let login: String
}

private struct ProbeCredentialStore: OAuthCredentialStore {
  let credential: GitHubOAuthCredentialBundle

  func load() async throws(any Error & Sendable) -> GitHubOAuthCredentialBundle? {
    credential
  }

  func save(_ credential: GitHubOAuthCredentialBundle) async throws(any Error & Sendable) {
    throw StoreError.writesDisabled
  }

  private enum StoreError: Error, Sendable { case writesDisabled }
}

private struct DisabledTokenFetcher: OAuthTokenFetcher {
  func refresh(
    _ credential: GitHubOAuthCredentialBundle
  ) async throws(OAuthTokenRefreshError) -> GitHubOAuthCredentialBundle {
    throw .credentialRejected
  }
}

private struct ProbeInput: Sendable {
  let login: String
  let positive: SampleIdentity
  let title: String
  let negatives: [SampleIdentity]
  let credential: GitHubOAuthCredentialBundle

  static func read() -> Self? {
    guard readHidden("已從 PR 詳情獨立核對下列樣本？輸入 yes：") == "yes",
      let login = readHidden("GitHub 帳號："), !login.isEmpty,
      let positiveText = readHidden("正例（owner/repo#number）："),
      let positive = SampleIdentity(positiveText),
      let title = readHidden("正例標題："), !title.isEmpty,
      let negativeText = readHidden("反例（逗號分隔的 owner/repo#number，可空白）："),
      let negatives = parseNegatives(negativeText),
      !negatives.contains(where: { $0.matches(positive) }),
      let credential = readCredential()
    else { return nil }

    return Self(
      login: login, positive: positive, title: title, negatives: negatives,
      credential: credential)
  }

  private static func readCredential() -> GitHubOAuthCredentialBundle? {
    guard let accessToken = readHidden("OAuth access token："), isToken(accessToken),
      let refreshToken = readHidden("OAuth refresh token："), isToken(refreshToken),
      let accessExpiry = readHidden("Access token 到期時間（RFC 3339）："),
      let refreshExpiry = readHidden("Refresh token 到期時間（RFC 3339）："),
      let accessDate = expirationDate(accessExpiry),
      let refreshDate = expirationDate(refreshExpiry),
      let scopes = readHidden("OAuth scopes（可空白）："),
      accessDate > Date(), refreshDate > Date()
    else { return nil }
    return GitHubOAuthCredentialBundle(
      accessToken: GitHubAccessToken(rawValue: accessToken),
      refreshToken: GitHubOAuthRefreshToken(rawValue: refreshToken),
      accessTokenExpiresAt: accessDate, refreshTokenExpiresAt: refreshDate,
      tokenType: .bearer, grantedScopes: scopes)
  }

  private static func parseNegatives(_ value: String) -> [SampleIdentity]? {
    if value.isEmpty { return [] }
    let parts = value.split(separator: ",", omittingEmptySubsequences: false)
    let samples = parts.compactMap { SampleIdentity($0.trimmingCharacters(in: .whitespaces)) }
    return samples.count == parts.count ? samples : nil
  }

  private static func isToken(_ value: String) -> Bool {
    !value.isEmpty && value.utf8.allSatisfy { (33...126).contains($0) }
  }

  private static func expirationDate(_ value: String) -> Date? {
    let parser = ISO8601DateFormatter()
    if let date = parser.date(from: value) { return date }
    parser.formatOptions.insert(.withFractionalSeconds)
    return parser.date(from: value)
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

private struct SampleIdentity: Sendable {
  let owner: String
  let repository: String
  let number: Int

  init?(_ value: String) {
    let segments = value.split(whereSeparator: { $0 == "/" || $0 == "#" })
    guard segments.count == 3, let number = Int(segments[2]), number > 0,
      value == "\(segments[0])/\(segments[1])#\(number)"
    else { return nil }
    owner = String(segments[0])
    repository = String(segments[1])
    self.number = number
  }

  func matches(_ item: InboxItem) -> Bool {
    matches(owner: item.owner, repository: item.repository, number: item.number)
  }

  func matches(_ sample: Self) -> Bool {
    matches(owner: sample.owner, repository: sample.repository, number: sample.number)
  }

  private func matches(owner: String, repository: String, number: Int) -> Bool {
    self.owner.caseInsensitiveCompare(owner) == .orderedSame
      && self.repository.caseInsensitiveCompare(repository) == .orderedSame && self.number == number
  }
}
