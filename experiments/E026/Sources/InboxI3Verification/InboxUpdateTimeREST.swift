import Foundation
import RivetHTTPClient

actor InboxUpdateTimeREST: InboxI3ReadOnlyREST {
  let rest: any InboxI3ReadOnlyREST
  private(set) var dates: [InboxI3Identity: Date] = [:]

  init(rest: any InboxI3ReadOnlyREST) {
    self.rest = rest
  }

  func executeGet(_ request: HTTPRequest) async throws -> HTTPResponse {
    let response = try await rest.executeGet(request)
    guard request.url.value.path == "/search/issues", response.statusCode == 200 else {
      return response
    }
    if let page = try? response.json(InboxI3SearchPage.self, decoder: JSONDecoder()) {
      for row in page.items {
        if let identity = row.identity {
          dates[identity] = row.date
        }
      }
    }
    return response
  }
}

private struct InboxI3SearchPage: Decodable, Sendable {
  let items: [InboxI3SearchRow]
}

private struct InboxI3SearchRow: Decodable, Sendable {
  let identity: InboxI3Identity?
  let date: Date?

  enum CodingKeys: String, CodingKey {
    case repositoryURL = "repository_url"
    case number
    case updatedAt = "updated_at"
  }

  init(from decoder: any Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    let url = try? values.decode(URL.self, forKey: .repositoryURL)
    let number = try? values.decode(Int.self, forKey: .number)
    if let url, let number, url.pathComponents.count == 4 {
      identity = InboxI3Identity(
        owner: url.pathComponents[2], repository: url.pathComponents[3], number: number)
    } else {
      identity = nil
    }

    if let text = try? values.decode(String.self, forKey: .updatedAt) {
      date =
        (try? Date.ISO8601FormatStyle().parse(text))
        ?? (try? Date.ISO8601FormatStyle(includingFractionalSeconds: true).parse(text))
    } else {
      date = nil
    }
  }
}
