// swift-format-ignore-file
// swiftlint:disable:next blanket_disable_command
// swiftlint:disable all
// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension ReaderGitHubGraphQL.Objects {
  /// Audit log entry for a repo.add_topic event.
  nonisolated static let RepoAddTopicAuditEntry = ApolloAPI.Object(
    typename: "RepoAddTopicAuditEntry",
    implementedInterfaces: [
      ReaderGitHubGraphQL.Interfaces.AuditEntry.self,
      ReaderGitHubGraphQL.Interfaces.Node.self,
      ReaderGitHubGraphQL.Interfaces.OrganizationAuditEntryData.self,
      ReaderGitHubGraphQL.Interfaces.RepositoryAuditEntryData.self,
      ReaderGitHubGraphQL.Interfaces.TopicAuditEntryData.self
    ],
    keyFields: nil
  )
}
