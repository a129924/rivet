import Foundation

public enum GitHubOAuth {
  public static func makeTokenFetcher(
    configuration: GitHubOAuthAppConfiguration
  ) throws -> any OAuthTokenFetcher {
    try validateConfiguration(configuration)
    return try GitHubOAuthHTTPTokenFetcher(
      configuration: .init(
        clientID: configuration.clientID, clientSecret: configuration.clientSecret))
  }

  public static func makeAuthorizationSession(
    configuration: GitHubOAuthAppConfiguration, redirectURI: URL
  ) throws -> GitHubOAuthAuthorizationSession {
    try validateConfiguration(configuration)
    let exchanger = try GitHubOAuthCodeExchanger()
    return try GitHubOAuthAuthorizationSession(
      configuration: configuration, redirectURI: redirectURI,
      state: randomValue(), verifier: randomValue(),
      exchange: { code, verifier in
        try await exchanger.exchange(
          configuration: configuration, code: code, redirectURI: redirectURI, verifier: verifier)
      })
  }

  private static func validateConfiguration(
    _ configuration: GitHubOAuthAppConfiguration
  ) throws(GitHubOAuthAuthorizationError) {
    guard !configuration.clientID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
      !configuration.clientSecret.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    else { throw .clientConfiguration }
  }

  private static func randomValue() -> String {
    var generator = SystemRandomNumberGenerator()
    return Data((0..<32).map { _ in UInt8.random(in: .min ... .max, using: &generator) })
      .base64EncodedString().replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "")
  }
}
