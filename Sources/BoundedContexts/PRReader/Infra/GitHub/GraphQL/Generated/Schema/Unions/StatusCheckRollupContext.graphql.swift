// swift-format-ignore-file
// swiftlint:disable:next blanket_disable_command
// swiftlint:disable all
// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension ReaderGitHubGraphQL.Unions {
  /// Types that can be inside a StatusCheckRollup context.
  nonisolated static let StatusCheckRollupContext = Union(
    name: "StatusCheckRollupContext",
    possibleTypes: [
      ReaderGitHubGraphQL.Objects.CheckRun.self,
      ReaderGitHubGraphQL.Objects.StatusContext.self
    ]
  )
}
