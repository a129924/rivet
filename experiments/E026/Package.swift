// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "InboxI3Verification",
  platforms: [.macOS(.v15)],
  dependencies: [
    .package(name: "Rivet", path: "../.."),
    .package(name: "RivetHTTPClient", path: "../../packages/RivetHTTPClient"),
    .package(path: "../support/InboxExperimentSupport"),
  ],
  targets: [
    .executableTarget(
      name: "InboxI3Verification",
      dependencies: [
        .product(name: "InboxExperimentSupport", package: "InboxExperimentSupport"),
        .product(name: "GitHubIntegration", package: "Rivet"),
        .product(name: "RivetHTTPClient", package: "RivetHTTPClient"),
        .product(name: "RivetPresentation", package: "Rivet"),
        .product(name: "RivetPRInbox", package: "Rivet"),
        .product(name: "RivetPRInboxGitHub", package: "Rivet"),
      ]
    ),
    .testTarget(
      name: "InboxI3VerificationTests",
      dependencies: [
        "InboxI3Verification",
        .product(name: "InboxExperimentSupport", package: "InboxExperimentSupport"),
      ]
    ),
  ]
)
