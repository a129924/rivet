// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "GitHubIntegrationConsumer",
  platforms: [.macOS(.v15)],
  dependencies: [
    .package(name: "Rivet", path: "../..")
  ],
  targets: [
    .testTarget(
      name: "GitHubIntegrationConsumerTests",
      dependencies: [
        .product(name: "GitHubIntegration", package: "Rivet")
      ]
    )
  ],
  swiftLanguageModes: [.v6]
)
