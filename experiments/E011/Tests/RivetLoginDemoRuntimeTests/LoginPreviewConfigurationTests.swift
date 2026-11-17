import RivetPresentation
import Testing

@testable import RivetLoginDemoRuntime

@Suite("Clean login preview") @MainActor
struct LoginPreviewConfigurationTests {
  @Test func defaultPreviewStartsAtWelcomeAndUsesNoSimulationCopy() throws {
    let configuration = try LoginPreviewConfiguration(arguments: ["--preview"])
    let host = LoginPreviewHost(configuration: configuration)
    #expect(host.model.phase == .welcome)
    #expect(configuration.appearance == .system)
    #expect(configuration.bodyPointSize == 13)
    #expect(!LoginPreviewConfiguration.footer.lowercased().contains("demo"))
    #expect(!LoginPreviewConfiguration.footer.lowercased().contains("simulat"))
    #expect(!LoginPreviewConfiguration.footer.lowercased().contains("stored"))
  }

  @Test func failureScenesUseNeutralCopyAndKeepExistingFakeEventRouting() throws {
    let browser = LoginPreviewHost(
      configuration: try .init(arguments: ["--preview", "--state", "browser-failure"]))
    guard case .failure(let failure) = browser.model.phase else {
      Issue.record("Expected the requested browser failure scene")
      return
    }
    #expect(failure.origin == .browser)
    #expect(failure.message != LoginDemoModel.failureMessage)
    #expect(!failure.message.lowercased().contains("simulat"))
    browser.model.handle(.retry)
    #expect(browser.model.phase == .waitingForBrowser)
    browser.model.handle(.cancelSignIn)
    #expect(browser.model.phase == .welcome)

    let token = LoginPreviewHost(
      configuration: try .init(arguments: ["--preview", "--state", "token-failure"]))
    guard case .failure(let tokenFailure) = token.model.phase else {
      Issue.record("Expected the requested token failure scene")
      return
    }
    #expect(tokenFailure.origin == .token)
    #expect(tokenFailure.message != LoginDemoModel.failureMessage)
    token.model.handle(.submitToken("local-preview-input"))
    #expect(token.model.phase == .verifyingToken)
    // No automatic completion or authentication is performed by the preview host.
    token.model.handle(.submitToken("ignored-repeat"))
    #expect(token.model.phase == .verifyingToken)
  }

  @Test(arguments: [
    ("welcome", RivetLoginPhase.welcome), ("pat", .tokenEntry),
    ("waiting", .waitingForBrowser), ("verifying-account", .verifyingAccount),
    ("verifying-token", .verifyingToken), ("completed", .connected),
  ])
  func requestedSceneBecomesInitialPhase(_ scene: String, _ expected: RivetLoginPhase) throws {
    let configuration = try LoginPreviewConfiguration(arguments: ["--preview", "--state", scene])
    #expect(LoginPreviewHost(configuration: configuration).model.phase == expected)
  }

  @Test(arguments: ["13", "17", "17.5", "21"])
  func launchAppearanceAndFiniteSupportedTextSizeAreApplied(_ size: String) throws {
    let configuration = try LoginPreviewConfiguration(
      arguments: ["--preview", "--appearance", "dark", "--text-size", size]
    )
    #expect(configuration.appearance == .dark)
    let expected = try #require(Double(size))
    #expect(Double(configuration.bodyPointSize) == expected)
  }

  @Test(arguments: [
    [], ["--state", "welcome"], ["--preview", "--state"], ["--preview", "--state", "unknown"],
    ["--preview", "--appearance", "unknown"], ["--preview", "--text-size", "nan"],
    ["--preview", "--text-size", "infinity"], ["--preview", "--text-size", "12.9"],
    ["--preview", "--text-size", "21.1"], ["--preview", "--unexpected", "value"],
    ["--preview", "--preview"], ["--preview", "--state", "pat", "--state", "welcome"],
  ])
  func invalidLaunchArgumentsAreRejectedBeforeCreatingAWindow(_ arguments: [String]) {
    #expect(throws: LoginPreviewConfigurationError.invalidArguments) {
      try LoginPreviewConfiguration(arguments: arguments)
    }
  }
}
