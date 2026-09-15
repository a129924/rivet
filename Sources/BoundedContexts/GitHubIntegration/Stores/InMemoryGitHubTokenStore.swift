public final class InMemoryGitHubTokenStore: GitHubTokenStore {
  private var token: GitHubAccessToken?

  public init() {}

  public func load() throws(TokenStoreError) -> GitHubAccessToken? {
    token
  }

  public func save(_ token: GitHubAccessToken) throws(TokenStoreError) {
    self.token = token
  }

  public func delete() throws(TokenStoreError) {
    token = nil
  }
}
