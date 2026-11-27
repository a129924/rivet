// swift-format-ignore-file
// swiftlint:disable:next blanket_disable_command
// swiftlint:disable all
// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension PRWriteGitHubGraphQL.Objects {
  /// Audit log entry for a org.oauth_app_access_requested event.
  nonisolated static let OrgOauthAppAccessRequestedAuditEntry = ApolloAPI.Object(
    typename: "OrgOauthAppAccessRequestedAuditEntry",
    implementedInterfaces: [
      PRWriteGitHubGraphQL.Interfaces.AuditEntry.self,
      PRWriteGitHubGraphQL.Interfaces.Node.self,
      PRWriteGitHubGraphQL.Interfaces.OauthApplicationAuditEntryData.self,
      PRWriteGitHubGraphQL.Interfaces.OrganizationAuditEntryData.self
    ],
    keyFields: nil
  )
}
