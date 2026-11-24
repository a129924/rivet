// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "E022InboxCancellation",
  platforms: [.macOS(.v15)],
  dependencies: [
    .package(name: "Rivet", path: "../.."),
    .package(path: "../../packages/RivetHTTPClient"),
  ],
  targets: [
    .executableTarget(
      name: "InboxCancellationProbe",
      dependencies: [
        .product(name: "GitHubIntegration", package: "Rivet"),
        .product(name: "RivetPRInbox", package: "Rivet"),
        .product(name: "RivetPRInboxGitHub", package: "Rivet"),
        .product(name: "RivetHTTPClient", package: "RivetHTTPClient"),
      ])
  ],
  swiftLanguageModes: [.v6]
)
