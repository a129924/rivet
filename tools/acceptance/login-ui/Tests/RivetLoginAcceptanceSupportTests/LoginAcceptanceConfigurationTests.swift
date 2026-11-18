import Testing

@testable import RivetLoginAcceptanceSupport

@Suite("Acceptance launch configuration")
struct LoginAcceptanceConfigurationTests {
  @Test func noArgumentsSelectProductDefaults() throws {
    let configuration = try LoginAcceptanceConfiguration(arguments: [])
    #expect(configuration.scene == .welcome)
    #expect(configuration.appearance == .system)
    #expect(configuration.bodyPointSize == 13)
  }

  @Test(arguments: LoginAcceptanceConfiguration.Scene.allCases)
  func everySceneCanBeSelectedAtLaunch(_ scene: LoginAcceptanceConfiguration.Scene) throws {
    let configuration = try LoginAcceptanceConfiguration(arguments: ["--state", scene.rawValue])
    #expect(configuration.scene == scene)
  }

  @Test(arguments: ["system", "light", "dark"], ["13", "17", "17.5", "21"])
  func appearanceAndSupportedFiniteSizesAreAccepted(_ appearance: String, _ value: String) throws {
    let configuration = try LoginAcceptanceConfiguration(arguments: [
      "--appearance", appearance, "--text-size", value,
    ])
    #expect(configuration.appearance.rawValue == appearance)
    let expected = try #require(Double(value))
    #expect(Double(configuration.bodyPointSize) == expected)
  }

  @Test(arguments: [
    ["--preview"], ["--state"], ["--state", "invalid"], ["--appearance", "invalid"],
    ["--state", "pat", "--state", "welcome"], ["--unexpected", "value"],
    ["--text-size", "nan"], ["--text-size", "infinity"], ["--text-size", "12"],
    ["--text-size", "22"],
  ])
  func invalidArgumentsFailBeforeOpeningAWindow(_ arguments: [String]) {
    #expect(throws: LoginAcceptanceConfigurationError.invalidArguments) {
      try LoginAcceptanceConfiguration(arguments: arguments)
    }
  }
}
