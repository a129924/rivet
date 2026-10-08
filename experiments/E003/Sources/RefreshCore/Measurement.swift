import CoreFoundation
import Foundation
import GitHubIntegration

struct CredentialResponse: Decodable {
  let accessToken: String
  let refreshToken: String
  let expiresIn: Int
  let refreshTokenExpiresIn: Int
  let tokenType: GitHubOAuthTokenType
  let scope: String

  enum CodingKeys: String, CodingKey {
    case accessToken = "access_token"
    case refreshToken = "refresh_token"
    case expiresIn = "expires_in"
    case refreshTokenExpiresIn = "refresh_token_expires_in"
    case tokenType = "token_type"
    case scope
  }

  var valid: Bool {
    !accessToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      && !refreshToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      && expiresIn > 0 && refreshTokenExpiresIn > 0
  }

  func bundle(receivedAt: Date) -> GitHubOAuthCredentialBundle {
    GitHubOAuthCredentialBundle(
      accessToken: .init(rawValue: accessToken), refreshToken: .init(rawValue: refreshToken),
      accessTokenExpiresAt: receivedAt.addingTimeInterval(TimeInterval(expiresIn)),
      refreshTokenExpiresAt: receivedAt.addingTimeInterval(TimeInterval(refreshTokenExpiresIn)),
      tokenType: tokenType, grantedScopes: scope)
  }
}

public enum Verdict: String, Sendable {
  case success = "成功"
  case failed = "失敗"
  case indeterminate = "無法判定"
}

public enum MeasurementReason: String, Sendable {
  case notExecuted = "前序條件未成立，未執行"
  case validInitial = "初始六欄相容且 API 200、user ID 有效"
  case validRefresh = "新 token pair、六欄、scope 與 public bundle 相容"
  case sameIdentity = "新 access token 的 user ID 一致"
  case rejectedOldRefresh = "舊 refresh token 回傳 bad_refresh_token 且無新 token"
  case invalidCredential = "有效回應的 credential 欄位或值不符"
  case invalidUser = "API status 或 user shape 不符"
  case changedIdentity = "新 access token 的 user ID 不一致"
  case oauthRejected = "OAuth error 可判讀且未取得預期 token"
  case freshRefreshRejected = "初始有效的 refresh token 被明確拒絕"
  case httpUnavailable = "HTTP 回應不足以判定"
  case interrupted = "網路、逾時或取消阻止測量"
  case rotationUnknown = "refresh 呼叫未取得可判讀回應，rotation 狀態未知"
  case unexpectedToken = "舊 refresh token 重用仍取得 token"
  case rejectionUnconfirmed = "舊 refresh token 拒絕原因未確認"
  case unexpectedOldRefreshError = "舊 refresh token 回傳非預期 OAuth error"
}

public struct Measurement: Sendable {
  public internal(set) var initial: Verdict = .indeterminate
  public internal(set) var refresh: Verdict = .indeterminate
  public internal(set) var newUser: Verdict = .indeterminate
  public internal(set) var oldRefresh: Verdict = .indeterminate
  public internal(set) var initialReason: MeasurementReason = .notExecuted
  public internal(set) var refreshReason: MeasurementReason = .notExecuted
  public internal(set) var newUserReason: MeasurementReason = .notExecuted
  public internal(set) var oldRefreshReason: MeasurementReason = .notExecuted
  public internal(set) var initialStatus: Int?
  public internal(set) var refreshStatus: Int?
  public internal(set) var newUserStatus: Int?
  public internal(set) var oldRefreshStatus: Int?
  public init() {}

  public var overall: Verdict {
    let axes = [initial, refresh, newUser, oldRefresh]
    if axes.contains(.failed) { return .failed }
    return axes.allSatisfy { $0 == .success } ? .success : .indeterminate
  }

  public var safeReport: String {
    func line(_ name: String, _ value: Verdict, _ why: MeasurementReason, _ code: Int?) -> String {
      let statusText = code.map(String.init) ?? "未取得"
      return "\(name)=\(value.rawValue), http=\(statusText), reason=\(why.rawValue)"
    }
    return [
      line("T01", initial, initialReason, initialStatus),
      line("T02", refresh, refreshReason, refreshStatus),
      line("T03", newUser, newUserReason, newUserStatus),
      line("T04", oldRefresh, oldRefreshReason, oldRefreshStatus),
      "overall=\(overall.rawValue)",
    ].joined(separator: "\n")
  }
}

public struct HTTPResult: Sendable {
  public let status: Int
  public let body: Data
  public let receivedAt: Date
  public init(status: Int, body: Data, receivedAt: Date = Date()) {
    self.status = status
    self.body = body
    self.receivedAt = receivedAt
  }
}

public protocol ProbeIO: Sendable {
  func authorize(state: String, challenge: String) async throws -> Authorization
  func exchange(authorization: Authorization, verifier: String) async throws -> HTTPResult
  func refresh(token: String) async throws -> HTTPResult
  func user(accessToken: String) async throws -> HTTPResult
  func close() async
}

struct CredentialCheck {
  let credential: CredentialResponse?
  let verdict: Verdict
  let reason: MeasurementReason
}

enum UserCheck {
  case valid(Int64)
  case invalid
  case unavailable
}

enum ResponseCheck {
  static func object(_ body: Data) -> [String: Any]? {
    (try? JSONSerialization.jsonObject(with: body)) as? [String: Any]
  }

  static func credential(_ response: HTTPResult, refreshing: Bool = false) -> CredentialCheck {
    guard let object = object(response.body) else {
      if refreshing {
        return CredentialCheck(credential: nil, verdict: .indeterminate, reason: .rotationUnknown)
      }
      let successfulHTTP = (200...299).contains(response.status)
      return CredentialCheck(
        credential: nil, verdict: successfulHTTP ? .failed : .indeterminate,
        reason: successfulHTTP ? .invalidCredential : .httpUnavailable)
    }
    if let error = object["error"] as? String, !error.isEmpty {
      if refreshing && error == "bad_refresh_token" {
        return CredentialCheck(credential: nil, verdict: .failed, reason: .freshRefreshRejected)
      }
      return CredentialCheck(credential: nil, verdict: .failed, reason: .oauthRejected)
    }
    guard (200...299).contains(response.status) else {
      return CredentialCheck(credential: nil, verdict: .indeterminate, reason: .httpUnavailable)
    }
    guard let credential = try? JSONDecoder().decode(CredentialResponse.self, from: response.body),
      credential.valid
    else { return CredentialCheck(credential: nil, verdict: .failed, reason: .invalidCredential) }
    return CredentialCheck(credential: credential, verdict: .success, reason: .validRefresh)
  }

  static func userID(_ response: HTTPResult) -> UserCheck {
    guard response.status == 200, let object = object(response.body) else {
      return .unavailable
    }
    guard
      let number = object["id"] as? NSNumber, CFGetTypeID(number) != CFBooleanGetTypeID(),
      number.doubleValue > 0, number.doubleValue.rounded() == number.doubleValue,
      number.doubleValue < Double(Int64.max),
      let login = object["login"] as? String, !login.isEmpty
    else { return .invalid }
    return .valid(number.int64Value)
  }

  static func oldRefresh(_ response: HTTPResult) -> (Verdict, MeasurementReason) {
    guard let object = object(response.body) else { return (.indeterminate, .rejectionUnconfirmed) }
    let hasToken = ["access_token", "refresh_token"].contains {
      guard let value = object[$0] as? String else { return false }
      return !value.isEmpty
    }
    if hasToken { return (.failed, .unexpectedToken) }
    guard let error = object["error"] as? String, !error.isEmpty else {
      return (.indeterminate, .rejectionUnconfirmed)
    }
    return error == "bad_refresh_token"
      ? (.success, .rejectedOldRefresh) : (.failed, .unexpectedOldRefreshError)
  }

  static func scopes(_ raw: String) -> Set<String> {
    Set(
      raw.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty })
  }
}

public enum Experiment {
  public static func run(transport: any ProbeIO) async -> Measurement {
    let result = await measure(transport: transport)
    await transport.close()
    return result
  }

  private static func measure(transport: any ProbeIO) async -> Measurement {
    var result = Measurement()
    let initialCredential: CredentialResponse
    do {
      try Task.checkCancellation()
      let verifier = try PKCE.random()
      let authorization = try await transport.authorize(
        state: PKCE.random(), challenge: PKCE.challenge(verifier))
      let response = try await transport.exchange(authorization: authorization, verifier: verifier)
      let check = ResponseCheck.credential(response)
      guard let credential = check.credential else {
        result.initial = check.verdict
        result.initialReason = check.reason
        return result
      }
      _ = credential.bundle(receivedAt: response.receivedAt)
      initialCredential = credential
      let user = try await transport.user(accessToken: credential.accessToken)
      result.initialStatus = user.status
      let identifier: Int64
      switch ResponseCheck.userID(user) {
      case .valid(let value):
        identifier = value
      case .invalid:
        result.initial = .failed
        result.initialReason = .invalidUser
        return result
      case .unavailable:
        result.initial = .indeterminate
        result.initialReason = .httpUnavailable
        return result
      }
      result.initial = .success
      result.initialReason = .validInitial
      return await refreshAndCompare(
        transport: transport, initial: initialCredential, userID: identifier, result: result)
    } catch {
      result.initialReason = .interrupted
      return result
    }
  }

  private static func refreshAndCompare(
    transport: any ProbeIO, initial: CredentialResponse, userID: Int64, result: Measurement
  ) async -> Measurement {
    var result = result
    guard !Task.isCancelled else {
      result.refreshReason = .interrupted
      return result
    }
    let response: HTTPResult
    do {
      response = try await transport.refresh(token: initial.refreshToken)
    } catch {
      result.refreshReason =
        (error as? ProbeFailure) == .interrupted
        ? .interrupted : .rotationUnknown
      return result
    }
    result.refreshStatus = response.status
    let check = ResponseCheck.credential(response, refreshing: true)
    guard let credential = check.credential else {
      result.refresh = check.verdict
      result.refreshReason = check.reason
      return result
    }
    guard credential.accessToken != initial.accessToken,
      credential.refreshToken != initial.refreshToken,
      ResponseCheck.scopes(credential.scope) == ResponseCheck.scopes(initial.scope)
    else {
      result.refresh = .failed
      result.refreshReason = .invalidCredential
      return result
    }
    _ = credential.bundle(receivedAt: response.receivedAt)
    result.refresh = .success
    result.refreshReason = .validRefresh

    do {
      try Task.checkCancellation()
      let user = try await transport.user(accessToken: credential.accessToken)
      result.newUserStatus = user.status
      switch ResponseCheck.userID(user) {
      case .valid(let refreshedID):
        result.newUser = refreshedID == userID ? .success : .failed
        result.newUserReason = refreshedID == userID ? .sameIdentity : .changedIdentity
      case .invalid:
        result.newUser = .failed
        result.newUserReason = .invalidUser
      case .unavailable:
        result.newUser = .indeterminate
        result.newUserReason = .httpUnavailable
      }
    } catch {
      result.newUserReason = .interrupted
      return result
    }

    do {
      try Task.checkCancellation()
      let oldResponse = try await transport.refresh(token: initial.refreshToken)
      result.oldRefreshStatus = oldResponse.status
      (result.oldRefresh, result.oldRefreshReason) = ResponseCheck.oldRefresh(oldResponse)
    } catch {
      result.oldRefreshReason = .interrupted
    }
    return result
  }
}
