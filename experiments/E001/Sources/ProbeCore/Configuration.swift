import Foundation
import Security

public struct ProbeConfiguration: Sendable {
  public let clientID: String
  public let timeoutSeconds: Int

  public init(arguments: [String]) throws {
    var clientID: String?
    var timeout: Int?
    var index = 0
    while index < arguments.count {
      guard index + 1 < arguments.count else { throw ConfigurationError.invalidArguments }
      let name = arguments[index]
      let value = arguments[index + 1]
      switch name {
      case "--client-id":
        guard clientID == nil, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
          !value.hasPrefix("--")
        else { throw ConfigurationError.invalidArguments }
        clientID = value
      case "--timeout-seconds":
        guard timeout == nil, value.allSatisfy(\.isNumber), let seconds = Int(value), seconds > 0
        else {
          throw ConfigurationError.invalidArguments
        }
        timeout = seconds
      default: throw ConfigurationError.invalidArguments
      }
      index += 2
    }
    guard let clientID else { throw ConfigurationError.invalidArguments }
    self.clientID = clientID
    timeoutSeconds = timeout ?? 180
  }

  func authorizationURL(port: UInt16, state: String) -> URL? {
    var components = URLComponents(string: "https://github.com/login/oauth/authorize")
    components?.queryItems = [
      URLQueryItem(name: "client_id", value: clientID),
      URLQueryItem(name: "redirect_uri", value: "http://127.0.0.1:\(port)/oauth/callback"),
      URLQueryItem(name: "state", value: state),
    ]
    return components?.url
  }
}

public enum ConfigurationError: Error {
  case invalidArguments
}

enum ProbeState {
  static func generate() throws -> String {
    var bytes = [UInt8](repeating: 0, count: 32)
    guard SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes) == errSecSuccess else {
      throw StateError.generationFailed
    }
    return bytes.map { String(format: "%02x", $0) }.joined()
  }

  private enum StateError: Error { case generationFailed }
}
