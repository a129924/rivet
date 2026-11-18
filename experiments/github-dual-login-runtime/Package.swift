// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "GitHubLoginRuntimeVerification",
  platforms: [.macOS(.v15)],
  dependencies: [.package(name: "Rivet", path: "../..")],
  targets: [
    .executableTarget(
      name: "GitHubLoginRuntimeVerification",
      dependencies: [.product(name: "GitHubIntegration", package: "Rivet")],
      path: "Sources"
    )
  ],
  swiftLanguageModes: [.v6]
)
