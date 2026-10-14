import Foundation
import GitHubIntegration
import Testing

@testable import SQLiteProbeCore

@Test func savesAndReloadsAllCredentialFields() async throws {
  let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
  try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
  defer { try? FileManager.default.removeItem(at: directory) }
  let path = directory.appendingPathComponent("credential.sqlite").path
  let credential = GitHubOAuthCredentialBundle(
    accessToken: GitHubAccessToken(rawValue: "fake-access-A"),
    refreshToken: GitHubOAuthRefreshToken(rawValue: "fake-refresh-A"),
    accessTokenExpiresAt: Date(timeIntervalSince1970: 2_000_000_120.125),
    refreshTokenExpiresAt: Date(timeIntervalSince1970: 2_000_008_640.5),
    tokenType: .bearer,
    grantedScopes: "repo read:user")
  try await SQLiteCredentialStore(path: path).save(credential)
  let restored = try #require(await SQLiteCredentialStore(path: path).load())
  #expect(restored.accessToken.rawValue == credential.accessToken.rawValue)
  #expect(restored.refreshToken.rawValue == credential.refreshToken.rawValue)
  #expect(restored.accessTokenExpiresAt == credential.accessTokenExpiresAt)
  #expect(restored.refreshTokenExpiresAt == credential.refreshTokenExpiresAt)
  #expect(restored.tokenType == credential.tokenType)
  #expect(restored.grantedScopes == credential.grantedScopes)
}

private func withDirectory(_ operation: (URL) async throws -> Void) async throws {
  let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
  try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
  defer { try? FileManager.default.removeItem(at: directory) }
  try await operation(directory)
}

@Test func expirationRotatesAndPersistsCompleteBundle() async throws {
  try await withDirectory {
    try await RuntimeScenarios.rotation(path: $0.appendingPathComponent("test.sqlite").path)
  }
}

@Test func overlappingDemandsRefreshOnceAndStaleSnapshotReusesCurrent() async throws {
  try await withDirectory {
    try await RuntimeScenarios.singleFlight(path: $0.appendingPathComponent("test.sqlite").path)
  }
}

@Test func actualPartialSQLWriteRollsBack() async throws {
  try await withDirectory {
    try await RuntimeScenarios.rollback(path: $0.appendingPathComponent("test.sqlite").path)
  }
}

@Test func acceptedRotationWithSaveFailureStopsProvider() async throws {
  try await withDirectory {
    try await RuntimeScenarios.persistenceFailure(
      path: $0.appendingPathComponent("test.sqlite").path)
  }
}

@Test func missingCorruptAndReadOnlyStorageStayDistinct() async throws {
  try await withDirectory { try await RuntimeScenarios.storageFailures(directory: $0) }
}
