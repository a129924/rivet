import CryptoKit
import Foundation
import Security

public enum ProbeFailure: Error, Sendable, Equatable {
  case invalidArguments, randomness, callback, denied, listener, browser, timeout, interrupted,
    network, noTTY
}

public enum PKCE {
  public static func challenge(_ verifier: String) -> String {
    encode(Data(SHA256.hash(data: Data(verifier.utf8))))
  }
  public static func random() throws -> String {
    var bytes = [UInt8](repeating: 0, count: 32)
    guard SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes) == errSecSuccess else {
      throw ProbeFailure.randomness
    }
    return encode(Data(bytes))
  }
  private static func encode(_ data: Data) -> String {
    data.base64EncodedString().replacingOccurrences(of: "+", with: "-").replacingOccurrences(
      of: "/", with: "_"
    )
    .replacingOccurrences(of: "=", with: "")
  }
}

public struct ProbeConfiguration: Sendable {
  public let clientID: String
  public let timeoutSeconds: Int
  public init(arguments: [String]) throws {
    var identifier: String?
    var timeout: Int?
    var index = 0
    while index < arguments.count {
      guard index + 1 < arguments.count else { throw ProbeFailure.invalidArguments }
      let value = arguments[index + 1]
      switch arguments[index] {
      case "--client-id":
        guard identifier == nil, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
          !value.hasPrefix("--")
        else { throw ProbeFailure.invalidArguments }
        identifier = value
      case "--timeout-seconds":
        guard timeout == nil, let seconds = Int(value), (1...180).contains(seconds) else {
          throw ProbeFailure.invalidArguments
        }
        timeout = seconds
      default: throw ProbeFailure.invalidArguments
      }
      index += 2
    }
    guard let identifier else { throw ProbeFailure.invalidArguments }
    clientID = identifier
    timeoutSeconds = timeout ?? 180
  }
  func authorizationURL(redirect: String, state: String, challenge: String) -> URL? {
    var components = URLComponents(string: "https://github.com/login/oauth/authorize")
    components?.queryItems = [
      .init(name: "client_id", value: clientID), .init(name: "redirect_uri", value: redirect),
      .init(name: "state", value: state), .init(name: "scope", value: "offline_access"),
      .init(name: "code_challenge", value: challenge),
      .init(name: "code_challenge_method", value: "S256"),
    ]
    return components?.url
  }
}

public struct Authorization: Sendable, Equatable {
  public let code: String
  public let redirect: String
}
public enum CallbackDecision: Sendable {
  case ignore(status: Int)
  case finish(Result<String, ProbeFailure>)
}
public enum Callback {
  public static func evaluate(
    method: String, target: String, expectedState: String
  ) -> CallbackDecision {
    guard target.hasPrefix("/"), !target.hasPrefix("//"),
      let components = URLComponents(string: "http://127.0.0.1" + target),
      components.fragment == nil
    else { return .ignore(status: 400) }
    guard components.path == "/oauth/callback" else { return .ignore(status: 404) }
    guard method == "GET" else { return .ignore(status: 405) }
    let items = components.queryItems ?? []
    guard Set(items.map(\.name)).count == items.count,
      let state = items.first(where: { $0.name == "state" })?.value,
      !state.isEmpty, state == expectedState
    else { return .finish(.failure(.callback)) }
    guard !items.contains(where: { $0.name == "error" }) else { return .finish(.failure(.denied)) }
    guard let code = items.first(where: { $0.name == "code" })?.value, !code.isEmpty else {
      return .finish(.failure(.callback))
    }
    return .finish(.success(code))
  }
}
