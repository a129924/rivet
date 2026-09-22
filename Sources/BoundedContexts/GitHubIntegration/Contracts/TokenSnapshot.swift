public struct TokenSnapshot: Equatable, Sendable {
  public let accessToken: GitHubAccessToken
  public let version: UInt64

  public func hasSameVersion(as other: Self) -> Bool {
    version == other.version
  }
}
