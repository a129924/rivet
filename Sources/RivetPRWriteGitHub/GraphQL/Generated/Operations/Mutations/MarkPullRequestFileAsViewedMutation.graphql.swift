// swift-format-ignore-file
// swiftlint:disable:next blanket_disable_command
// swiftlint:disable all
// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension PRWriteGitHubGraphQL {
  nonisolated struct MarkPullRequestFileAsViewedMutation: GraphQLMutation {
    static let operationName: String = "MarkPullRequestFileAsViewed"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation MarkPullRequestFileAsViewed($pullRequestId: ID!, $path: String!) { markFileAsViewed(input: { pullRequestId: $pullRequestId, path: $path }) { __typename pullRequest { __typename id } } }"#
      ))

    public var pullRequestId: ID
    public var path: String

    public init(
      pullRequestId: ID,
      path: String
    ) {
      self.pullRequestId = pullRequestId
      self.path = path
    }

    @_spi(Unsafe) public var __variables: Variables? { [
      "pullRequestId": pullRequestId,
      "path": path
    ] }

    nonisolated struct Data: PRWriteGitHubGraphQL.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { PRWriteGitHubGraphQL.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("markFileAsViewed", MarkFileAsViewed?.self, arguments: ["input": [
          "pullRequestId": .variable("pullRequestId"),
          "path": .variable("path")
        ]]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        MarkPullRequestFileAsViewedMutation.Data.self
      ] }

      /// Mark a pull request file as viewed
      var markFileAsViewed: MarkFileAsViewed? { __data["markFileAsViewed"] }

      /// MarkFileAsViewed
      ///
      /// Parent Type: `MarkFileAsViewedPayload`
      nonisolated struct MarkFileAsViewed: PRWriteGitHubGraphQL.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { PRWriteGitHubGraphQL.Objects.MarkFileAsViewedPayload }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("pullRequest", PullRequest?.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          MarkPullRequestFileAsViewedMutation.Data.MarkFileAsViewed.self
        ] }

        /// The updated pull request.
        var pullRequest: PullRequest? { __data["pullRequest"] }

        /// MarkFileAsViewed.PullRequest
        ///
        /// Parent Type: `PullRequest`
        nonisolated struct PullRequest: PRWriteGitHubGraphQL.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { PRWriteGitHubGraphQL.Objects.PullRequest }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", PRWriteGitHubGraphQL.ID.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            MarkPullRequestFileAsViewedMutation.Data.MarkFileAsViewed.PullRequest.self
          ] }

          /// The Node ID of the PullRequest object
          var id: PRWriteGitHubGraphQL.ID { __data["id"] }
        }
      }
    }
  }

}
