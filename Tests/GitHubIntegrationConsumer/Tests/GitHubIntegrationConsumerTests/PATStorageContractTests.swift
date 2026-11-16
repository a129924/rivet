import GitHubIntegration
import Testing

@Suite("Public PAT storage contract (no Security operations)")
struct PATStorageContractTests {
  @Test
  func publicStoreCanBeConstructedAndSentWithoutAccessingKeychain() throws {
    let store = try GitHubPATDataProtectionStore(accessGroup: "consumer.explicit.group")
    requirePATSendable(store)
    let load: @Sendable () async throws(GitHubPATDataProtectionStoreError) -> PersonalAccessToken? =
      {
        try await store.load()
      }
    let save:
      @Sendable (PersonalAccessToken) async throws(GitHubPATDataProtectionStoreError) -> Void = {
        try await store.save($0)
      }
    // Compile both public operations without executing real Security in the consumer.
    requirePATSendable(load)
    requirePATSendable(save)
  }

  @Test
  func invalidPublicConfigurationFailsLocally() {
    #expect(throws: GitHubPATDataProtectionStoreError.invalidConfiguration) {
      try GitHubPATDataProtectionStore(accessGroup: "")
    }
    #expect(throws: GitHubPATDataProtectionStoreError.invalidConfiguration) {
      try GitHubPATDataProtectionStore(accessGroup: "team.*")
    }
    #expect(throws: GitHubPATDataProtectionStoreError.invalidConfiguration) {
      try GitHubPATDataProtectionStore(accessGroup: "group", service: " \n")
    }
  }

  @Test
  func publicErrorsAreFiniteAndSendable() {
    for error: GitHubPATDataProtectionStoreError in [
      .denied, .unavailable, .corrupt, .invalidConfiguration,
    ] {
      requirePATSendable(error)
      #expect(classify(error))
    }
  }

  private func classify(_ error: GitHubPATDataProtectionStoreError) -> Bool {
    switch error {
    case .denied, .unavailable, .corrupt, .invalidConfiguration: true
    }
  }
}

private func requirePATSendable<Value: Sendable>(_ value: Value) {}
