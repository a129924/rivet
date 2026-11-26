package struct ReaderReviewThread: Equatable, Sendable {
  package enum Subject: Equatable, Sendable {
    case file
    case line
  }

  package struct Comment: Equatable, Sendable {
    package let id: String
    package let body: String
    package let author: String?
    package let replyToID: String?
  }

  package let id: String
  package let path: String
  package let subject: Subject
  package let line: Int?
  package let startLine: Int?
  package let originalLine: Int?
  package let originalStartLine: Int?
  package let isResolved: Bool
  package let isOutdated: Bool
  package let comments: [Comment]
}
