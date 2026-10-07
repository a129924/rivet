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
  case notExecuted = "未執行：前序測量尚未成功"
  case tokenAcquired = "正向交換取得非空 token"
  case invalidExchangeResponse = "交換回應不是 JSON object"
  case noToken = "有效交換回應未取得非空 access token"
  case credentialsUnavailable = "credentials 前置條件不足，停止測量"
  case redirectUnconfirmed = "redirect 前置條件不符，停止測量"
  case unconfirmedOAuthError = "OAuth error 原因未確認，停止測量"
  case httpUnavailable = "HTTP 非成功回應不足以完成有效測量"
  case schemaCompatible = "schema 六欄相容且可建 public bundle"
  case schemaIncompatible = "schema 六欄不相容"
  case userValidated = "API 200 且 user shape 有效"
  case userInvalid = "API status 或 user shape 不符"
  case interrupted = "網路、逾時或取消阻止測量"
  case stoppedBeforeNegative = "前序中止，未執行反向授權"
  case negativeToken = "錯誤 verifier 仍取得 token"
  case controlledRejection = "新 code 單次立即交換受拒；正向 baseline 與相同 App／secret／redirect／state 支持受控歸因"
  case rejectionUnconfirmed = "反向回應／錯誤未確認，無法歸因"
}

public struct Measurement: Sendable {
  public internal(set) var exchange: Verdict = .indeterminate
  public internal(set) var schema: Verdict = .indeterminate
  public internal(set) var api: Verdict = .indeterminate
  public internal(set) var pkce: Verdict = .indeterminate
  public internal(set) var exchangeReason: MeasurementReason = .notExecuted
  public internal(set) var schemaReason: MeasurementReason = .notExecuted
  public internal(set) var apiReason: MeasurementReason = .notExecuted
  public internal(set) var pkceReason: MeasurementReason = .notExecuted
  public init() {}
  public var overall: Verdict {
    let axes = [exchange, schema, api, pkce]
    if axes.contains(.failed) { return .failed }
    return axes.allSatisfy { $0 == .success } ? .success : .indeterminate
  }
  public var safeReport: String {
    "exchange=\(exchange.rawValue), schema=\(schema.rawValue), API=\(api.rawValue), "
      + "PKCE=\(pkce.rawValue), overall=\(overall.rawValue)\n"
      + "exchange：\(exchangeReason.rawValue)\n"
      + "schema：\(schemaReason.rawValue)\n"
      + "API：\(apiReason.rawValue)\n"
      + "PKCE：\(pkceReason.rawValue)"
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
  func user(accessToken: String) async throws -> HTTPResult
  func close() async
}

public enum ResponseCheck {
  enum Positive {
    case token(String)
    case stop(Verdict, MeasurementReason)
  }
  static func positive(_ response: HTTPResult) -> Positive {
    guard let object = object(response.body) else {
      return (200...299).contains(response.status)
        ? .stop(.failed, .invalidExchangeResponse) : .stop(.indeterminate, .httpUnavailable)
    }
    if object["error"] != nil {
      let reason: MeasurementReason
      switch object["error"] as? String {
      case "incorrect_client_credentials": reason = .credentialsUnavailable
      case "redirect_uri_mismatch": reason = .redirectUnconfirmed
      default: reason = .unconfirmedOAuthError
      }
      return .stop(.indeterminate, reason)
    }
    guard (200...299).contains(response.status) else {
      return .stop(.indeterminate, .httpUnavailable)
    }
    guard let accessToken = token(object, key: "access_token") else {
      return .stop(.failed, .noToken)
    }
    return .token(accessToken)
  }
  static func negative(_ response: HTTPResult) -> (Verdict, MeasurementReason) {
    guard let object = object(response.body) else { return (.indeterminate, .rejectionUnconfirmed) }
    let hasToken =
      token(object, key: "access_token") != nil || token(object, key: "refresh_token") != nil
    if hasToken { return (.failed, .negativeToken) }
    return object["error"] as? String == "bad_verification_code"
      ? (.success, .controlledRejection) : (.indeterminate, .rejectionUnconfirmed)
  }

  static func object(_ data: Data) -> [String: Any]? {
    (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
  }
  static func token(_ object: [String: Any], key: String) -> String? {
    guard let token = object[key] as? String, !token.isEmpty else { return nil }
    return token
  }
  static func validUser(_ response: HTTPResult) -> Bool {
    guard response.status == 200, let object = object(response.body),
      let identifier = object["id"] as? NSNumber, CFGetTypeID(identifier) != CFBooleanGetTypeID(),
      identifier.doubleValue > 0, identifier.doubleValue.rounded() == identifier.doubleValue,
      let login = object["login"] as? String, !login.isEmpty
    else { return false }
    return true
  }
}

public enum Experiment {
  private enum Stage { case exchange, api, pkce }
  public static func run(transport: any ProbeIO) async -> Measurement {
    var result = Measurement()
    var stage = Stage.exchange
    do {
      try Task.checkCancellation()
      let verifier = try PKCE.random()
      let authorization = try await transport.authorize(
        state: PKCE.random(), challenge: PKCE.challenge(verifier))
      let response = try await transport.exchange(authorization: authorization, verifier: verifier)
      let accessToken: String
      switch ResponseCheck.positive(response) {
      case .token(let token): accessToken = token
      case .stop(let verdict, let reason):
        result.exchange = verdict
        result.exchangeReason = reason
        await transport.close()
        return result
      }
      result.exchange = .success
      result.exchangeReason = .tokenAcquired
      if let credential = try? JSONDecoder().decode(CredentialResponse.self, from: response.body) {
        _ = credential.bundle(receivedAt: response.receivedAt)
        result.schema = .success
        result.schemaReason = .schemaCompatible
      } else {
        result.schema = .failed
        result.schemaReason = .schemaIncompatible
      }
      stage = .api
      result.api =
        ResponseCheck.validUser(try await transport.user(accessToken: accessToken))
        ? .success : .failed
      result.apiReason = result.api == .success ? .userValidated : .userInvalid
      stage = .pkce
      try Task.checkCancellation()
      let negativeVerifier = try PKCE.random()
      var wrongVerifier = try PKCE.random()
      while PKCE.challenge(wrongVerifier) == PKCE.challenge(negativeVerifier) {
        wrongVerifier = try PKCE.random()
      }
      let negative = try await transport.authorize(
        state: PKCE.random(), challenge: PKCE.challenge(negativeVerifier))
      let rejection = try await transport.exchange(authorization: negative, verifier: wrongVerifier)
      (result.pkce, result.pkceReason) = ResponseCheck.negative(rejection)
    } catch {
      switch stage {
      case .exchange: result.exchangeReason = .interrupted
      case .api:
        result.apiReason = .interrupted
        result.pkceReason = .stoppedBeforeNegative
      case .pkce: result.pkceReason = .interrupted
      }
    }
    await transport.close()
    return result
  }
}
