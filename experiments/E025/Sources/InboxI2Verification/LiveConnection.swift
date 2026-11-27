import Foundation
import GitHubIntegration
import RivetHTTPClient
import Security

actor LiveConnection {
  private let restorer: GitHubOAuthStartupRestorer?
  private var rest: (any GitHubRestClient)?

  init(accessGroup: String?, service: String?) {
    let stores = accessGroup.flatMap { group -> GitHubOAuthDataProtectionStores? in
      guard let task = SecTaskCreateFromSelf(nil),
        let groups = SecTaskCopyValueForEntitlement(task, "keychain-access-groups" as CFString, nil)
          as? [String], groups.contains(group)
      else { return nil }
      if let service {
        return try? GitHubOAuthDataProtectionStores(accessGroup: group, service: service)
      } else {
        return try? GitHubOAuthDataProtectionStores(accessGroup: group)
      }
    }
    restorer = stores.map { GitHubOAuthStartupRestorer(stores: $0) }
  }

  func refresh() async -> InboxLoadResult {
    if let rest { return await query(rest) }
    guard let restorer else { return .liveNotRun(.missingConfiguration) }

    switch await restorer.restore() {
    case .ready(let scope):
      rest = scope.rest
      return await query(scope.rest)
    case .notConfigured, .notSignedIn:
      return .liveNotRun(.notSignedIn)
    case .authenticationRequired:
      return .liveNotRun(.authenticationRequired)
    case .failed, .cancelled, .busy:
      return .liveNotRun(.restoreFailed)
    }
  }

  private func query(_ rest: any GitHubRestClient) async -> InboxLoadResult {
    let observed = ViewerREST(rest: rest)
    let result = await loadInbox(using: observed)
    guard case .success(let items, _) = result, let viewer = await observed.viewer else {
      return .unavailable
    }
    return .success(items, viewer: viewer)
  }
}

private actor ViewerREST: InboxReadOnlyREST {
  private struct Viewer: Decodable, Sendable {
    let login: String
  }

  let rest: any GitHubRestClient
  private(set) var viewer: String?

  init(rest: any GitHubRestClient) {
    self.rest = rest
  }

  func executeGet(_ request: HTTPRequest) async throws -> HTTPResponse {
    let response = try await rest.executeGet(request)
    if request.url.value.path == "/user", response.statusCode == 200 {
      viewer = try response.json(Viewer.self, decoder: JSONDecoder()).login
    }
    return response
  }
}
