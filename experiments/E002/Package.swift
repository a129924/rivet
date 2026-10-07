// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "OAuthPKCEProbe", platforms: [.macOS(.v15)],
  products: [.executable(name: "oauth-pkce-probe", targets: ["OAuthPKCEProbe"])],
  dependencies: [.package(name: "Rivet", path: "../..")],
  targets: [
    .target(
      name: "PKCECore", dependencies: [.product(name: "GitHubIntegration", package: "Rivet")]),
    .executableTarget(name: "OAuthPKCEProbe", dependencies: ["PKCECore"]),
    .testTarget(name: "PKCECoreTests", dependencies: ["PKCECore"]),
  ], swiftLanguageModes: [.v6]
)
