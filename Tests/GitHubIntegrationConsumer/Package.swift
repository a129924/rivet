// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "GitHubIntegrationConsumer",
  platforms: [.macOS(.v15)],
  dependencies: [
    .package(name: "Rivet", path: "../.."),
    .package(url: "https://github.com/apollographql/apollo-ios.git", exact: "2.1.2"),
    .package(path: "../../packages/RivetHTTPClient"),
  ],
  targets: [
    .testTarget(
      name: "GitHubIntegrationConsumerTests",
      dependencies: [
        .product(name: "GitHubIntegration", package: "Rivet"),
        .product(name: "Apollo", package: "apollo-ios"),
        .product(name: "ApolloAPI", package: "apollo-ios"),
        .product(name: "RivetHTTPClient", package: "RivetHTTPClient"),
      ]
    )
  ],
  swiftLanguageModes: [.v6]
)
