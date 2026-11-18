import Darwin
import Foundation
import GitHubIntegration

/// Verification-only entry. No operation runs without both explicit local readiness inputs.
@main struct GitHubLoginRuntimeVerification {
  @MainActor static func main() async {
    let arguments = Array(CommandLine.arguments.dropFirst())
    let environment = ProcessInfo.processInfo.environment
    guard arguments.count == 2, arguments[0] == "--human-ready",
      environment["RIVET_LOGIN_LIVE_READY"] == "human-confirmed"
    else {
      print("驗證專用；未執行網路或憑證操作。請先閱讀本入口 README 的 Human 停點。")
      return
    }
    do {
      try await run(arguments[1], environment: environment)
    } catch {
      // Never print raw framework errors, paths, configuration, or credential values.
      print("verification=failed")
      exit(1)
    }
  }

  @MainActor private static func run(_ mode: String, environment: [String: String]) async throws {
    guard ["login-oauth", "login-pat", "readback-oauth", "readback-pat"].contains(mode),
      let group = environment["RIVET_LOGIN_ACCESS_GROUP"], !group.isEmpty,
      let oauthService = environment["RIVET_LOGIN_OAUTH_SERVICE"], !oauthService.isEmpty,
      let patService = environment["RIVET_LOGIN_PAT_SERVICE"], !patService.isEmpty,
      oauthService != patService
    else { throw VerificationFailure.configuration }
    let oauth = try GitHubOAuthDataProtectionStores(accessGroup: group, service: oauthService)
    let pat = try GitHubPATDataProtectionStore(accessGroup: group, service: patService)
    if mode == "readback-pat" {
      print(try await pat.load() == nil ? "pat=absent" : "pat=present")
      return
    }
    let needsOAuth = mode == "login-oauth" || mode == "readback-oauth"
    let clientID = environment["RIVET_LOGIN_CLIENT_ID"] ?? "pat-only-verification"
    guard !needsOAuth || environment["RIVET_LOGIN_CLIENT_ID"] != nil else {
      throw VerificationFailure.configuration
    }
    if mode == "readback-oauth" {
      print(
        try await oauth.credentialStore(clientID: clientID).load() == nil
          ? "oauth=absent" : "oauth=present")
      return
    }
    let configuration = try GitHubOAuthAppConfiguration(
      clientID: clientID, clientSecret: needsOAuth ? readSecret("OAuth client secret: ") : "unused")
    let service = GitHubLoginService(
      configuration: configuration, oauthStores: oauth, patStore: pat,
      coordinator: GitHubLoginCoordinator())
    let request: LoginRequest =
      needsOAuth ? .oauth : .pat(try PersonalAccessToken(rawValue: readSecret("PAT: ")))
    switch await service.authenticate(request) {
    case .success: print("login=success")
    case .failure: print("login=failed")
    case .cancelled: print("login=cancelled")
    }
  }

  @MainActor private static func readSecret(_ prompt: String) throws -> String {
    guard isatty(STDIN_FILENO) == 1, let buffer = getpass(prompt) else {
      throw VerificationFailure.configuration
    }
    defer { memset(buffer, 0, strlen(buffer)) }
    return String(cString: buffer)
  }

  private enum VerificationFailure: Error { case configuration }
}
