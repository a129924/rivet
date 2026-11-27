import Foundation
import RivetHTTPClient

package enum GitHubUnreadNotificationsOutcome: Sendable, Equatable {
  case success([GitHubNotificationThread])
  case failure(GitHubUnreadNotificationsFailure)
  case cancelled
}

package enum GitHubUnreadNotificationsFailure: Error, Sendable, Equatable {
  case accessDenied
  case unavailable
  case incompletePagination
  case invalidData
}

package struct GitHubNotificationThread: Sendable, Equatable {
  package let id: String
  package let unread: Bool
  package let updatedAt: Date
  package let lastReadAt: Date?
  package let subject: Subject
  package let repository: Repository

  package struct Subject: Sendable, Equatable {
    package let title: String
    package let type: String
    package let url: String?
    package let latestCommentURL: String?
  }

  package struct Repository: Sendable, Equatable {
    package let id: Int64
    package let fullName: String
  }

  static func decodePage(
    _ response: HTTPResponse, excluding token: PersonalAccessToken
  ) throws(GitHubUnreadNotificationsFailure) -> [Self] {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .custom { decoder in
      let value = try decoder.singleValueContainer().decode(String.self)
      if let date = try? Date.ISO8601FormatStyle(includingFractionalSeconds: true).parse(value) {
        return date
      }
      return try Date.ISO8601FormatStyle().parse(value)
    }

    guard let threads = try? response.json([ThreadPayload].self, decoder: decoder) else {
      throw .invalidData
    }
    return try threads.map { entry throws(GitHubUnreadNotificationsFailure) in
      let subject = entry.subject
      let repository = entry.repository
      let retainedStrings: [String?] = [
        entry.id, subject.title, subject.type, subject.url, subject.latestCommentURL,
        repository.fullName,
      ]
      // Even a credential echoed in a successful payload must stay out of the result.
      guard !entry.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
        repository.id > 0,
        !repository.fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
        !retainedStrings.compactMap({ $0 }).contains(where: { $0.contains(token.rawValue) })
      else { throw .invalidData }

      return Self(
        id: entry.id, unread: entry.unread,
        updatedAt: entry.updatedAt, lastReadAt: entry.lastReadAt,
        subject: Subject(
          title: subject.title, type: subject.type, url: subject.url,
          latestCommentURL: subject.latestCommentURL),
        repository: Repository(id: repository.id, fullName: repository.fullName))
    }
  }
}

private struct ThreadPayload: Decodable, Sendable {
  let id: String
  let unread: Bool
  let updatedAt: Date
  let lastReadAt: Date?
  let subject: SubjectPayload
  let repository: RepositoryPayload

  enum CodingKeys: String, CodingKey {
    case id, unread, subject, repository
    case updatedAt = "updated_at"
    case lastReadAt = "last_read_at"
  }
}

private struct SubjectPayload: Decodable, Sendable {
  let title: String
  let type: String
  let url: String?
  let latestCommentURL: String?

  enum CodingKeys: String, CodingKey {
    case title, type, url
    case latestCommentURL = "latest_comment_url"
  }
}

private struct RepositoryPayload: Decodable, Sendable {
  let id: Int64
  let fullName: String

  enum CodingKeys: String, CodingKey {
    case id
    case fullName = "full_name"
  }
}
