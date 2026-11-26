// swift-format-ignore-file
// swiftlint:disable:next blanket_disable_command
// swiftlint:disable all
// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension ReaderGitHubGraphQL.Interfaces {
  /// Represents an event related to a project on the timeline of an issue or pull request.
  nonisolated static let ProjectV2Event = ApolloAPI.Interface(
    name: "ProjectV2Event",
    keyFields: nil,
    implementingObjects: [
      "AddedToProjectV2Event",
      "ConvertedFromDraftEvent",
      "ProjectV2ItemStatusChangedEvent",
      "RemovedFromProjectV2Event"
    ]
  )
}
