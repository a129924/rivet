import Testing

@testable import GitHubIntegration

@Suite("GitHub header requirements")
struct GitHubHeadersFactoryTests {
  @Test func defaultsSelectTheExistingRESTHeaders() throws {
    let factory = GitHubHeadersFactory.standard
    let standard = try factory.make(requirements: [.standardREST])
    let login = try factory.make(requirements: [.loginRuntimeREST])

    #expect(try factory.make(requirements: []) == standard)
    #expect(
      standard.values == [
        "accept": "application/vnd.github+json",
        "user-agent": "Rivet",
        "x-github-api-version": "2026-03-10",
      ])
    #expect(
      login.values == ["accept": "application/vnd.github+json", "user-agent": "RivetLoginRuntime"])
    #expect(standard.value(for: "X-GitHub-API-Version") == "2026-03-10")
    #expect(standard.authorization == nil)
    #expect(login.authorization == nil)
  }

  @Test func diffSelectsOneAcceptAndKeepsTheStandardRESTMetadata() throws {
    let factory = GitHubHeadersFactory.standard
    let diff = try factory.make(requirements: [.pullRequestUnifiedDiffREST])

    #expect(
      diff.values == [
        "accept": "application/vnd.github.diff",
        "user-agent": "Rivet",
        "x-github-api-version": "2026-03-10",
      ])
  }

  @Test func repeatedRequirementsSelectTheSameHeaders() throws {
    let factory = GitHubHeadersFactory.standard

    #expect(
      try factory.make(requirements: [.standardREST, .standardREST])
        == factory.make(requirements: [.standardREST]))
    #expect(
      try factory.make(requirements: [.loginRuntimeREST, .loginRuntimeREST])
        == factory.make(requirements: [.loginRuntimeREST]))
    #expect(
      try factory.make(requirements: [.pullRequestUnifiedDiffREST, .pullRequestUnifiedDiffREST])
        == factory.make(requirements: [.pullRequestUnifiedDiffREST]))
  }

  @Test(
    arguments: [
      [.standardREST, .loginRuntimeREST],
      [.loginRuntimeREST, .standardREST],
      [.standardREST, .standardREST, .loginRuntimeREST],
      [.standardREST, .pullRequestUnifiedDiffREST],
      [.pullRequestUnifiedDiffREST, .standardREST],
      [.loginRuntimeREST, .pullRequestUnifiedDiffREST],
      [.pullRequestUnifiedDiffREST, .loginRuntimeREST],
      [.standardREST, .loginRuntimeREST, .pullRequestUnifiedDiffREST],
    ] as [[GitHubHeaderRequirement]])
  func conflictingRequirementsFailRegardlessOfOrder(_ requirements: [GitHubHeaderRequirement]) {
    #expect(throws: GitHubHeadersFactory.CompositionError.conflictingRESTRequirements) {
      try GitHubHeadersFactory.standard.make(requirements: requirements)
    }
  }

  @Test func injectedConfigurationProducesIndependentHeaderValues() throws {
    let configuration = try GitHubHeadersConfiguration(
      restAccept: "application/json", standardUserAgent: "Rivet Fixture",
      loginUserAgent: "Rivet Login Fixture", apiVersion: "2040-01-01")
    let factory = GitHubHeadersFactory(configuration: configuration)

    var copy = try factory.make(requirements: [.standardREST])
    #expect(copy.accept == "application/json")
    #expect(copy.userAgent == "Rivet Fixture")
    #expect(copy.value(for: "X-GitHub-Api-Version") == "2040-01-01")
    copy.accept = "application/octet-stream"
    copy.authorization = "fixture"

    let subsequent = try factory.make(requirements: [.standardREST])
    let login = try factory.make(requirements: [.loginRuntimeREST])
    #expect(subsequent.accept == "application/json")
    #expect(subsequent.authorization == nil)
    #expect(login.accept == "application/json")
    #expect(login.userAgent == "Rivet Login Fixture")
    #expect(login.value(for: "X-GitHub-Api-Version") == nil)

    let diff = try factory.make(requirements: [.pullRequestUnifiedDiffREST])
    #expect(diff.accept == "application/vnd.github.diff")
    #expect(diff.userAgent == "Rivet Fixture")
    #expect(diff.value(for: "X-GitHub-Api-Version") == "2040-01-01")
    #expect(diff.authorization == nil)
  }

  @Test(arguments: ["", " \t", "value\rnext", "value\nnext", "value\r\nnext"])
  func rejectsInvalidValuesInEveryField(_ invalid: String) {
    #expect(throws: GitHubHeadersConfiguration.ValidationError.invalidValue(.restAccept)) {
      try GitHubHeadersConfiguration(
        restAccept: invalid, standardUserAgent: "Rivet",
        loginUserAgent: "RivetLoginRuntime", apiVersion: "2026-03-10")
    }
    #expect(throws: GitHubHeadersConfiguration.ValidationError.invalidValue(.standardUserAgent)) {
      try GitHubHeadersConfiguration(
        restAccept: "application/json", standardUserAgent: invalid,
        loginUserAgent: "RivetLoginRuntime", apiVersion: "2026-03-10")
    }
    #expect(throws: GitHubHeadersConfiguration.ValidationError.invalidValue(.loginUserAgent)) {
      try GitHubHeadersConfiguration(
        restAccept: "application/json", standardUserAgent: "Rivet",
        loginUserAgent: invalid, apiVersion: "2026-03-10")
    }
    #expect(throws: GitHubHeadersConfiguration.ValidationError.invalidValue(.apiVersion)) {
      try GitHubHeadersConfiguration(
        restAccept: "application/json", standardUserAgent: "Rivet",
        loginUserAgent: "RivetLoginRuntime", apiVersion: invalid)
    }
  }

  @Test func preservesValidConfigurationValues() throws {
    let configuration = try GitHubHeadersConfiguration(
      restAccept: "application/json ", standardUserAgent: " Rivet",
      loginUserAgent: "Rivet Login", apiVersion: "2040-01-01")
    let factory = GitHubHeadersFactory(configuration: configuration)
    let standard = try factory.make(requirements: [.standardREST])
    #expect(standard.accept == "application/json ")
    #expect(standard.userAgent == " Rivet")
  }
}
