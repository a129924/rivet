import GitHubIntegration
import RivetPRReader
import RivetPRReaderGitHub
import RivetPRReaderPresentation

@MainActor
package func makePRReaderBackgroundSession(
  rest: any GitHubRestClient
) -> PRReaderBackgroundSession {
  let source = GitHubPullRequestBackgroundSource(client: rest)
  return PRReaderBackgroundSession(facade: PRReaderBackgroundFacade(source: source))
}
