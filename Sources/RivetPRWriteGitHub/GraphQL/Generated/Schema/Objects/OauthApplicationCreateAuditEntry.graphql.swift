// swift-format-ignore-file
// swiftlint:disable:next blanket_disable_command
// swiftlint:disable all
// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension PRWriteGitHubGraphQL.Objects {
  /// Audit log entry for a oauth_application.create event.
  nonisolated static let OauthApplicationCreateAuditEntry = ApolloAPI.Object(
    typename: "OauthApplicationCreateAuditEntry",
    implementedInterfaces: [
      PRWriteGitHubGraphQL.Interfaces.AuditEntry.self,
      PRWriteGitHubGraphQL.Interfaces.Node.self,
      PRWriteGitHubGraphQL.Interfaces.OauthApplicationAuditEntryData.self,
      PRWriteGitHubGraphQL.Interfaces.OrganizationAuditEntryData.self
    ],
    keyFields: nil
  )
}
