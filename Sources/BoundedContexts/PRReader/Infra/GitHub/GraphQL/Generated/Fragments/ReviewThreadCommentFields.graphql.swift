// swift-format-ignore-file
// swiftlint:disable:next blanket_disable_command
// swiftlint:disable all
// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension ReaderGitHubGraphQL {
  nonisolated struct ReviewThreadCommentFields: ReaderGitHubGraphQL.SelectionSet, Fragment {
    static var fragmentDefinition: StaticString {
      #"fragment ReviewThreadCommentFields on PullRequestReviewComment { __typename id body author { __typename login } replyTo { __typename id } pullRequest { __typename id } }"#
    }

    let __data: DataDict
    init(_dataDict: DataDict) { __data = _dataDict }

    static var __parentType: any ApolloAPI.ParentType { ReaderGitHubGraphQL.Objects.PullRequestReviewComment }
    static var __selections: [ApolloAPI.Selection] { [
      .field("__typename", String.self),
      .field("id", ReaderGitHubGraphQL.ID.self),
      .field("body", String.self),
      .field("author", Author?.self),
      .field("replyTo", ReplyTo?.self),
      .field("pullRequest", PullRequest.self),
    ] }
    static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
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

    /// Author
    ///
    /// Parent Type: `Actor`
    nonisolated struct Author: ReaderGitHubGraphQL.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { ReaderGitHubGraphQL.Interfaces.Actor }
      static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("login", String.self),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        ReviewThreadCommentFields.Author.self
      ] }

      /// The username of the actor.
      var login: String { __data["login"] }
    }

    /// ReplyTo
    ///
    /// Parent Type: `PullRequestReviewComment`
    nonisolated struct ReplyTo: ReaderGitHubGraphQL.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { ReaderGitHubGraphQL.Objects.PullRequestReviewComment }
      static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", ReaderGitHubGraphQL.ID.self),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        ReviewThreadCommentFields.ReplyTo.self
      ] }

      /// The Node ID of the PullRequestReviewComment object
      var id: ReaderGitHubGraphQL.ID { __data["id"] }
    }

    /// PullRequest
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
        ReviewThreadCommentFields.PullRequest.self
      ] }

      /// The Node ID of the PullRequest object
      var id: ReaderGitHubGraphQL.ID { __data["id"] }
    }
  }

}
