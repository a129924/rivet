public struct TokenStoreGitHubTokenProvider: GitHubTokenProvider {
  private let store: any GitHubTokenStore

  public init(store: any GitHubTokenStore) {
    self.store = store
  }

  public func token() throws(GitHubCredentialError) -> GitHubAccessToken {
    let token: GitHubAccessToken?

    do {
      token = try store.load()
    } catch let error {
      throw .tokenStore(error)
    }

    guard let token else {
      throw .missingCredential
    }

    return token
  }
}
