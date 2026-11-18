// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "E020SelfReviewProbe",
  platforms: [.macOS(.v15)],
  dependencies: [
    .package(name: "Rivet", path: "../.."),
    .package(path: "../../packages/RivetHTTPClient"),
  ],
  targets: [
    .executableTarget(
      name: "pr-inbox-self-review-probe",
      dependencies: [
        .product(name: "GitHubIntegration", package: "Rivet"),
        .product(name: "RivetPRInbox", package: "Rivet"),
        .product(name: "RivetPRInboxGitHub", package: "Rivet"),
        .product(name: "RivetHTTPClient", package: "RivetHTTPClient"),
      ],
      path: "Sources/SelfReviewProbe"
    )
  ],
  swiftLanguageModes: [.v6]
)
