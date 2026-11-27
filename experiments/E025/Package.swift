// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "InboxI2Verification",
  platforms: [.macOS(.v15)],
  dependencies: [
    .package(name: "Rivet", path: "../.."),
    .package(name: "RivetHTTPClient", path: "../../packages/RivetHTTPClient"),
  ],
  targets: [
    .executableTarget(
      name: "InboxI2Verification",
      dependencies: [
        .product(name: "GitHubIntegration", package: "Rivet"),
        .product(name: "RivetHTTPClient", package: "RivetHTTPClient"),
        .product(name: "RivetPresentation", package: "Rivet"),
        .product(name: "RivetPRInbox", package: "Rivet"),
        .product(name: "RivetPRInboxGitHub", package: "Rivet"),
      ]
    ),
    .testTarget(
      name: "InboxI2VerificationTests",
      dependencies: ["InboxI2Verification"]
    ),
  ]
)
