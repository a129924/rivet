// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "OAuthRefreshProbe", platforms: [.macOS(.v15)],
  products: [.executable(name: "oauth-refresh-probe", targets: ["OAuthRefreshProbe"])],
  dependencies: [.package(name: "Rivet", path: "../..")],
  targets: [
    .target(
      name: "RefreshCore", dependencies: [.product(name: "GitHubIntegration", package: "Rivet")]),
    .executableTarget(name: "OAuthRefreshProbe", dependencies: ["RefreshCore"]),
    .testTarget(name: "RefreshCoreTests", dependencies: ["RefreshCore"]),
  ], swiftLanguageModes: [.v6]
)
