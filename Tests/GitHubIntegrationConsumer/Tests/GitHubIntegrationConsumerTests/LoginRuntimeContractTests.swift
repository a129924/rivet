import GitHubIntegration
import Testing

@Suite("Public login runtime construction (no network or Security)")
struct LoginRuntimeContractTests {
  @Test func sharedCoordinatorAndServiceAreSendable() throws {
    let configuration = try GitHubOAuthAppConfiguration(
      clientID: "fixture-id", clientSecret: "fixture-secret")
    let oauth = try GitHubOAuthDataProtectionStores(accessGroup: "consumer.explicit.group")
    let pat = try GitHubPATDataProtectionStore(accessGroup: "consumer.explicit.group")
    let coordinator = GitHubLoginCoordinator()
    let service = GitHubLoginService(
      configuration: configuration, oauthStores: oauth, patStore: pat, coordinator: coordinator)
    let authenticator: any LoginAuthenticating = service
    requireSendable(service)
    requireSendable(coordinator)
    requireSendable(authenticator)
    // Construction and compile-only composition never invoke authenticate, network, or Security.
    #expect(Mirror(reflecting: service).children.isEmpty)
  }
}

private func requireSendable<Value: Sendable>(_ value: Value) {}
