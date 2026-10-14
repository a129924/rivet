import Foundation
import GRDB
import GitHubIntegration

public enum ProbeStoreError: Error, Sendable {
  case invalidTokenType
  case faultFixtureMissing
  case partialWriteNotObserved
  case injectedAfterPartialWrite
}

/// Experiment-only adapter. This database holds fake credentials, without encryption.
public actor SQLiteCredentialStore: OAuthCredentialStore {
  private let path: String
  private let readOnly: Bool
  private var queue: DatabaseQueue?
  private var injectPartialWriteFailure = false
  public private(set) var observedPartialWrite = false
  public private(set) var saveCalls = 0

  public init(path: String, readOnly: Bool = false) {
    self.path = path
    self.readOnly = readOnly
  }

  public func armPartialWriteFailure() {
    injectPartialWriteFailure = true
  }

  public func load() async throws(any Error & Sendable) -> GitHubOAuthCredentialBundle? {
    try await database().read { database in
      guard let row = try Row.fetchOne(database, sql: "SELECT * FROM credential WHERE id = 1")
      else {
        return nil
      }
      let tokenType: String = row["token_type"]
      guard let type = GitHubOAuthTokenType(rawValue: tokenType) else {
        throw ProbeStoreError.invalidTokenType
      }
      return GitHubOAuthCredentialBundle(
        accessToken: GitHubAccessToken(rawValue: row["access_token"]),
        refreshToken: GitHubOAuthRefreshToken(rawValue: row["refresh_token"]),
        accessTokenExpiresAt: Date(timeIntervalSince1970: row["access_expires_at"]),
        refreshTokenExpiresAt: Date(timeIntervalSince1970: row["refresh_expires_at"]),
        tokenType: type,
        grantedScopes: row["scope"])
    }
  }

  public func save(_ credential: GitHubOAuthCredentialBundle) async throws(any Error & Sendable) {
    saveCalls += 1
    let shouldFail = injectPartialWriteFailure
    do {
      try await database().write { database in
        if shouldFail {
          guard
            let before = try Row.fetchOne(database, sql: "SELECT * FROM credential WHERE id = 1")
          else {
            throw ProbeStoreError.faultFixtureMissing
          }
          try database.execute(
            sql: "UPDATE credential SET access_token = ? WHERE id = 1",
            arguments: [credential.accessToken.rawValue])
          guard
            let after = try Row.fetchOne(database, sql: "SELECT * FROM credential WHERE id = 1"),
            after["access_token"] as String == credential.accessToken.rawValue,
            after["access_token"] as String != before["access_token"] as String,
            after["refresh_token"] as String == before["refresh_token"] as String
          else {
            throw ProbeStoreError.partialWriteNotObserved
          }
          // The SELECT observed real, uncommitted mixed data. GRDB must roll it back.
          throw ProbeStoreError.injectedAfterPartialWrite
        }
        try database.execute(
          sql: """
            INSERT INTO credential
              (id, access_token, refresh_token, access_expires_at, refresh_expires_at, token_type, scope)
            VALUES (1, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(id) DO UPDATE SET
              access_token = excluded.access_token,
              refresh_token = excluded.refresh_token,
              access_expires_at = excluded.access_expires_at,
              refresh_expires_at = excluded.refresh_expires_at,
              token_type = excluded.token_type,
              scope = excluded.scope
            """,
          arguments: [
            credential.accessToken.rawValue, credential.refreshToken.rawValue,
            credential.accessTokenExpiresAt.timeIntervalSince1970,
            credential.refreshTokenExpiresAt.timeIntervalSince1970,
            credential.tokenType.rawValue, credential.grantedScopes,
          ])
      }
    } catch ProbeStoreError.injectedAfterPartialWrite {
      observedPartialWrite = true
      throw ProbeStoreError.injectedAfterPartialWrite
    }
  }

  private func database() throws -> DatabaseQueue {
    if let queue { return queue }
    var configuration = Configuration()
    configuration.readonly = readOnly
    let opened = try DatabaseQueue(path: path, configuration: configuration)
    if !readOnly {
      try opened.write { database in
        try database.execute(
          sql: """
            CREATE TABLE IF NOT EXISTS credential (
              id INTEGER PRIMARY KEY CHECK (id = 1),
              access_token TEXT NOT NULL,
              refresh_token TEXT NOT NULL,
              access_expires_at REAL NOT NULL,
              refresh_expires_at REAL NOT NULL,
              token_type TEXT NOT NULL,
              scope TEXT NOT NULL
            )
            """)
      }
    }
    queue = opened
    return opened
  }
}
