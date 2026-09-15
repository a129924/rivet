import GitHubIntegration
import Testing

@Suite("In-memory GitHub token store")
struct InMemoryGitHubTokenStoreTests {
  @Test
  func emptyStoreLoadsNoToken() throws {
    let store = InMemoryGitHubTokenStore()

    #expect(try store.load() == nil)
  }

  @Test
  func savedTokenLoadsUnchanged() throws {
    let store = InMemoryGitHubTokenStore()
    let expected = GitHubAccessToken(rawValue: "first-token")

    try store.save(expected)

    #expect(try store.load()?.rawValue == expected.rawValue)
  }

  @Test
  func laterSaveReplacesThePreviousToken() throws {
    let store = InMemoryGitHubTokenStore()

    try store.save(GitHubAccessToken(rawValue: "first-token"))
    try store.save(GitHubAccessToken(rawValue: "replacement-token"))

    #expect(try store.load()?.rawValue == "replacement-token")
  }

  @Test
  func separateStoreStartsEmpty() throws {
    let savedStore = InMemoryGitHubTokenStore()
    try savedStore.save(GitHubAccessToken(rawValue: "stored-token"))
    let separateStore = InMemoryGitHubTokenStore()

    #expect(try separateStore.load() == nil)
  }

  @Test
  func deleteClearsTheSavedToken() throws {
    let store = InMemoryGitHubTokenStore()
    try store.save(GitHubAccessToken(rawValue: "stored-token"))

    try store.delete()

    #expect(try store.load() == nil)
  }

  @Test
  func deletingAnEmptyStoreKeepsItEmpty() throws {
    let store = InMemoryGitHubTokenStore()

    try store.delete()

    #expect(try store.load() == nil)
  }
}
