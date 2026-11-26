// swift-format-ignore-file
// swiftlint:disable:next blanket_disable_command
// swiftlint:disable all
// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension ReaderGitHubGraphQL {
  nonisolated struct ReviewThreadsQuery: GraphQLQuery {
    static let operationName: String = "ReviewThreads"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query ReviewThreads($owner: String!, $name: String!, $number: Int!, $after: String) { repository(owner: $owner, name: $name) { __typename id nameWithOwner pullRequest(number: $number) { __typename id number repository { __typename id } reviewThreads(first: 50, after: $after) { __typename pageInfo { __typename hasNextPage endCursor } nodes { __typename id path subjectType line startLine originalLine originalStartLine isResolved isOutdated pullRequest { __typename id } comments(first: 20) { __typename pageInfo { __typename hasNextPage endCursor } nodes { __typename ...ReviewThreadCommentFields } } } } } } }"#,
        fragments: [ReviewThreadCommentFields.self]
      ))

    public var owner: String
    public var name: String
    public var number: Int32
    public var after: GraphQLNullable<String>

    public init(
      owner: String,
      name: String,
      number: Int32,
      after: GraphQLNullable<String>
    ) {
      self.owner = owner
      self.name = name
      self.number = number
      self.after = after
    }

    @_spi(Unsafe) public var __variables: Variables? { [
      "owner": owner,
      "name": name,
      "number": number,
      "after": after
    ] }

    nonisolated struct Data: ReaderGitHubGraphQL.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { ReaderGitHubGraphQL.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("repository", Repository?.self, arguments: [
          "owner": .variable("owner"),
          "name": .variable("name")
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        ReviewThreadsQuery.Data.self
      ] }

      /// Lookup a given repository by the owner and repository name.
      var repository: Repository? { __data["repository"] }

      /// Repository
      ///
      /// Parent Type: `Repository`
      nonisolated struct Repository: ReaderGitHubGraphQL.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { ReaderGitHubGraphQL.Objects.Repository }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", ReaderGitHubGraphQL.ID.self),
          .field("nameWithOwner", String.self),
          .field("pullRequest", PullRequest?.self, arguments: ["number": .variable("number")]),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          ReviewThreadsQuery.Data.Repository.self
        ] }

        /// The Node ID of the Repository object
        var id: ReaderGitHubGraphQL.ID { __data["id"] }
        /// The repository's name with owner.
        var nameWithOwner: String { __data["nameWithOwner"] }
        /// Returns a single pull request from the current repository by number.
        var pullRequest: PullRequest? { __data["pullRequest"] }

        /// Repository.PullRequest
        ///
        /// Parent Type: `PullRequest`
        nonisolated struct PullRequest: ReaderGitHubGraphQL.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { ReaderGitHubGraphQL.Objects.PullRequest }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", ReaderGitHubGraphQL.ID.self),
            .field("number", Int.self),
            .field("repository", Repository.self),
            .field("reviewThreads", ReviewThreads.self, arguments: [
              "first": 50,
              "after": .variable("after")
            ]),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            ReviewThreadsQuery.Data.Repository.PullRequest.self
          ] }

          /// The Node ID of the PullRequest object
          var id: ReaderGitHubGraphQL.ID { __data["id"] }
          /// Identifies the pull request number.
          var number: Int { __data["number"] }
          /// The repository associated with this node.
          var repository: Repository { __data["repository"] }
          /// The list of all review threads for this pull request.
          var reviewThreads: ReviewThreads { __data["reviewThreads"] }

          /// Repository.PullRequest.Repository
          ///
          /// Parent Type: `Repository`
          nonisolated struct Repository: ReaderGitHubGraphQL.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { ReaderGitHubGraphQL.Objects.Repository }
            static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("id", ReaderGitHubGraphQL.ID.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              ReviewThreadsQuery.Data.Repository.PullRequest.Repository.self
            ] }

            /// The Node ID of the Repository object
            var id: ReaderGitHubGraphQL.ID { __data["id"] }
          }

          /// Repository.PullRequest.ReviewThreads
          ///
          /// Parent Type: `PullRequestReviewThreadConnection`
          nonisolated struct ReviewThreads: ReaderGitHubGraphQL.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { ReaderGitHubGraphQL.Objects.PullRequestReviewThreadConnection }
            static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("pageInfo", PageInfo.self),
              .field("nodes", [Node?]?.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              ReviewThreadsQuery.Data.Repository.PullRequest.ReviewThreads.self
            ] }

            /// Information to aid in pagination.
            var pageInfo: PageInfo { __data["pageInfo"] }
            /// A list of nodes.
            var nodes: [Node?]? { __data["nodes"] }

            /// Repository.PullRequest.ReviewThreads.PageInfo
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
                ReviewThreadsQuery.Data.Repository.PullRequest.ReviewThreads.PageInfo.self
              ] }

              /// When paginating forwards, are there more items?
              var hasNextPage: Bool { __data["hasNextPage"] }
              /// When paginating forwards, the cursor to continue.
              var endCursor: String? { __data["endCursor"] }
            }

            /// Repository.PullRequest.ReviewThreads.Node
            ///
            /// Parent Type: `PullRequestReviewThread`
            nonisolated struct Node: ReaderGitHubGraphQL.SelectionSet {
              let __data: DataDict
              init(_dataDict: DataDict) { __data = _dataDict }

              static var __parentType: any ApolloAPI.ParentType { ReaderGitHubGraphQL.Objects.PullRequestReviewThread }
              static var __selections: [ApolloAPI.Selection] { [
                .field("__typename", String.self),
                .field("id", ReaderGitHubGraphQL.ID.self),
                .field("path", String.self),
                .field("subjectType", GraphQLEnum<ReaderGitHubGraphQL.PullRequestReviewThreadSubjectType>.self),
                .field("line", Int?.self),
                .field("startLine", Int?.self),
                .field("originalLine", Int?.self),
                .field("originalStartLine", Int?.self),
                .field("isResolved", Bool.self),
                .field("isOutdated", Bool.self),
                .field("pullRequest", PullRequest.self),
                .field("comments", Comments.self, arguments: ["first": 20]),
              ] }
              static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                ReviewThreadsQuery.Data.Repository.PullRequest.ReviewThreads.Node.self
              ] }

              /// The Node ID of the PullRequestReviewThread object
              var id: ReaderGitHubGraphQL.ID { __data["id"] }
              /// Identifies the file path of this thread.
              var path: String { __data["path"] }
              /// The level at which the comments in the corresponding thread are targeted, can be a diff line or a file
              var subjectType: GraphQLEnum<ReaderGitHubGraphQL.PullRequestReviewThreadSubjectType> { __data["subjectType"] }
              /// The line in the file to which this thread refers
              var line: Int? { __data["line"] }
              /// The start line in the file to which this thread refers (multi-line only)
              var startLine: Int? { __data["startLine"] }
              /// The original line in the file to which this thread refers.
              var originalLine: Int? { __data["originalLine"] }
              /// The original start line in the file to which this thread refers (multi-line only).
              var originalStartLine: Int? { __data["originalStartLine"] }
              /// Whether this thread has been resolved
              var isResolved: Bool { __data["isResolved"] }
              /// Indicates whether this thread was outdated by newer changes.
              var isOutdated: Bool { __data["isOutdated"] }
              /// Identifies the pull request associated with this thread.
              var pullRequest: PullRequest { __data["pullRequest"] }
              /// A list of pull request comments associated with the thread.
              var comments: Comments { __data["comments"] }

              /// Repository.PullRequest.ReviewThreads.Node.PullRequest
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
                  ReviewThreadsQuery.Data.Repository.PullRequest.ReviewThreads.Node.PullRequest.self
                ] }

                /// The Node ID of the PullRequest object
                var id: ReaderGitHubGraphQL.ID { __data["id"] }
              }

              /// Repository.PullRequest.ReviewThreads.Node.Comments
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
                  ReviewThreadsQuery.Data.Repository.PullRequest.ReviewThreads.Node.Comments.self
                ] }

                /// Information to aid in pagination.
                var pageInfo: PageInfo { __data["pageInfo"] }
                /// A list of nodes.
                var nodes: [Node?]? { __data["nodes"] }

                /// Repository.PullRequest.ReviewThreads.Node.Comments.PageInfo
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
                    ReviewThreadsQuery.Data.Repository.PullRequest.ReviewThreads.Node.Comments.PageInfo.self
                  ] }

                  /// When paginating forwards, are there more items?
                  var hasNextPage: Bool { __data["hasNextPage"] }
                  /// When paginating forwards, the cursor to continue.
                  var endCursor: String? { __data["endCursor"] }
                }

                /// Repository.PullRequest.ReviewThreads.Node.Comments.Node
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
                    ReviewThreadsQuery.Data.Repository.PullRequest.ReviewThreads.Node.Comments.Node.self,
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
  }

}
