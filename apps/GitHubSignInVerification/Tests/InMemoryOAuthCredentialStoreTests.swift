import Foundation
import GitHubIntegration
import Testing

@testable import GitHubSignInVerification

struct InMemoryOAuthCredentialStoreTests {
  @Test func storesAndReplacesAllCredentialFieldsWithoutCrossInstanceRestore() async {
    let store = InMemoryOAuthCredentialStore()
    #expect(await store.load() == nil)
    let credential = appFixtureCredential()
    await store.save(credential)
    let loaded = await store.load()
    #expect(loaded?.accessToken.rawValue == credential.accessToken.rawValue)
    #expect(loaded?.refreshToken.rawValue == credential.refreshToken.rawValue)
    #expect(loaded?.accessTokenExpiresAt == credential.accessTokenExpiresAt)
    #expect(loaded?.refreshTokenExpiresAt == credential.refreshTokenExpiresAt)
    #expect(loaded?.tokenType == .bearer)
    #expect(loaded?.grantedScopes == "fixture-scope")
    #expect(await InMemoryOAuthCredentialStore().load() == nil)
    await store.save(appFixtureCredential(access: "replacement"))
    #expect(await store.load()?.accessToken.rawValue == "replacement")
  }
}

func appFixtureCredential(access: String = "fixture-access") -> GitHubOAuthCredentialBundle {
  .init(
    accessToken: .init(rawValue: access), refreshToken: .init(rawValue: "fixture-refresh"),
    accessTokenExpiresAt: Date().addingTimeInterval(3600),
    refreshTokenExpiresAt: Date().addingTimeInterval(7200),
    tokenType: .bearer, grantedScopes: "fixture-scope")
}
