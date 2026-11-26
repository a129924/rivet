// swift-format-ignore-file
// swiftlint:disable:next blanket_disable_command
// swiftlint:disable all
// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension ReaderGitHubGraphQL {
  nonisolated struct ReviewThreadCommentsQuery: GraphQLQuery {
    static let operationName: String = "ReviewThreadComments"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query ReviewThreadComments($threadID: ID!, $after: String!) { node(id: $threadID) { __typename ... on PullRequestReviewThread { id pullRequest { __typename id } comments(first: 20, after: $after) { __typename pageInfo { __typename hasNextPage endCursor } nodes { __typename ...ReviewThreadCommentFields } } } } }"#,
        fragments: [ReviewThreadCommentFields.self]
      ))

    public var threadID: ID
    public var after: String

    public init(
      threadID: ID,
      after: String
    ) {
      self.threadID = threadID
      self.after = after
    }

    @_spi(Unsafe) public var __variables: Variables? { [
      "threadID": threadID,
      "after": after
    ] }

    nonisolated struct Data: ReaderGitHubGraphQL.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { ReaderGitHubGraphQL.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("node", Node?.self, arguments: ["id": .variable("threadID")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        ReviewThreadCommentsQuery.Data.self
      ] }

      /// Fetches an object given its ID.
      var node: Node? { __data["node"] }

      /// Node
      ///
      /// Parent Type: `Node`
      nonisolated struct Node: ReaderGitHubGraphQL.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { ReaderGitHubGraphQL.Interfaces.Node }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .inlineFragment(AsPullRequestReviewThread.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          ReviewThreadCommentsQuery.Data.Node.self
        ] }

        var asPullRequestReviewThread: AsPullRequestReviewThread? { _asInlineFragment() }

        /// Node.AsPullRequestReviewThread
        ///
        /// Parent Type: `PullRequestReviewThread`
        nonisolated struct AsPullRequestReviewThread: ReaderGitHubGraphQL.InlineFragment {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          typealias RootEntityType = ReviewThreadCommentsQuery.Data.Node
          static var __parentType: any ApolloAPI.ParentType { ReaderGitHubGraphQL.Objects.PullRequestReviewThread }
          static var __selections: [ApolloAPI.Selection] { [
            .field("id", ReaderGitHubGraphQL.ID.self),
            .field("pullRequest", PullRequest.self),
            .field("comments", Comments.self, arguments: [
              "first": 20,
              "after": .variable("after")
            ]),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            ReviewThreadCommentsQuery.Data.Node.self,
            ReviewThreadCommentsQuery.Data.Node.AsPullRequestReviewThread.self
          ] }

          /// The Node ID of the PullRequestReviewThread object
          var id: ReaderGitHubGraphQL.ID { __data["id"] }
          /// Identifies the pull request associated with this thread.
          var pullRequest: PullRequest { __data["pullRequest"] }
          /// A list of pull request comments associated with the thread.
          var comments: Comments { __data["comments"] }

          /// Node.AsPullRequestReviewThread.PullRequest
          ///
          /// Parent Type: `PullRequest`
          nonisolated struct PullRequest: ReaderGitHubGraphQL.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { ReaderGitHubGraphQL.Objects.PullRequest }
            static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("id", ReaderGitHubGraphQL.ID.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              ReviewThreadCommentsQuery.Data.Node.AsPullRequestReviewThread.PullRequest.self
            ] }

            /// The Node ID of the PullRequest object
            var id: ReaderGitHubGraphQL.ID { __data["id"] }
          }

          /// Node.AsPullRequestReviewThread.Comments
          ///
          /// Parent Type: `PullRequestReviewCommentConnection`
          nonisolated struct Comments: ReaderGitHubGraphQL.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { ReaderGitHubGraphQL.Objects.PullRequestReviewCommentConnection }
            static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("pageInfo", PageInfo.self),
              .field("nodes", [Node?]?.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              ReviewThreadCommentsQuery.Data.Node.AsPullRequestReviewThread.Comments.self
            ] }

            /// Information to aid in pagination.
            var pageInfo: PageInfo { __data["pageInfo"] }
            /// A list of nodes.
            var nodes: [Node?]? { __data["nodes"] }

            /// Node.AsPullRequestReviewThread.Comments.PageInfo
            ///
            /// Parent Type: `PageInfo`
            nonisolated struct PageInfo: ReaderGitHubGraphQL.SelectionSet {
              let __data: DataDict
              init(_dataDict: DataDict) { __data = _dataDict }

              static var __parentType: any ApolloAPI.ParentType { ReaderGitHubGraphQL.Objects.PageInfo }
              static var __selections: [ApolloAPI.Selection] { [
                .field("__typename", String.self),
                .field("hasNextPage", Bool.self),
                .field("endCursor", String?.self),
              ] }
              static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                ReviewThreadCommentsQuery.Data.Node.AsPullRequestReviewThread.Comments.PageInfo.self
              ] }

              /// When paginating forwards, are there more items?
              var hasNextPage: Bool { __data["hasNextPage"] }
              /// When paginating forwards, the cursor to continue.
              var endCursor: String? { __data["endCursor"] }
            }

            /// Node.AsPullRequestReviewThread.Comments.Node
            ///
            /// Parent Type: `PullRequestReviewComment`
            nonisolated struct Node: ReaderGitHubGraphQL.SelectionSet {
              let __data: DataDict
              init(_dataDict: DataDict) { __data = _dataDict }

              static var __parentType: any ApolloAPI.ParentType { ReaderGitHubGraphQL.Objects.PullRequestReviewComment }
              static var __selections: [ApolloAPI.Selection] { [
                .field("__typename", String.self),
                .fragment(ReviewThreadCommentFields.self),
              ] }
              static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                ReviewThreadCommentsQuery.Data.Node.AsPullRequestReviewThread.Comments.Node.self,
                ReviewThreadCommentFields.self
              ] }

              /// The Node ID of the PullRequestReviewComment object
              var id: ReaderGitHubGraphQL.ID { __data["id"] }
              /// The comment body of this review comment.
              var body: String { __data["body"] }
              /// The actor who authored the comment.
              var author: Author? { __data["author"] }
              /// The comment this is a reply to.
              var replyTo: ReplyTo? { __data["replyTo"] }
              /// The pull request associated with this review comment.
              var pullRequest: PullRequest { __data["pullRequest"] }

              struct Fragments: FragmentContainer {
                let __data: DataDict
                init(_dataDict: DataDict) { __data = _dataDict }

                var reviewThreadCommentFields: ReviewThreadCommentFields { _toFragment() }
              }

              typealias Author = ReviewThreadCommentFields.Author

              typealias ReplyTo = ReviewThreadCommentFields.ReplyTo

              typealias PullRequest = ReviewThreadCommentFields.PullRequest
            }
          }
        }
      }
    }
  }

}
