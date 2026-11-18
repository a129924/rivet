// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "E019InboxProbe",
  platforms: [.macOS(.v15)],
  products: [.executable(name: "pr-inbox-probe", targets: ["InboxProbe"])],
  dependencies: [
    .package(name: "Rivet", path: "../.."),
    .package(path: "../../packages/RivetHTTPClient"),
  ],
  targets: [
    .target(
      name: "InboxSearch",
      dependencies: [
        .product(name: "GitHubIntegration", package: "Rivet"),
        .product(name: "RivetPRInbox", package: "Rivet"),
        .product(name: "RivetHTTPClient", package: "RivetHTTPClient"),
      ]
    ),
    .executableTarget(
      name: "InboxProbe",
      dependencies: [
        "InboxSearch",
        .product(name: "GitHubIntegration", package: "Rivet"),
        .product(name: "RivetPRInbox", package: "Rivet"),
        .product(name: "RivetHTTPClient", package: "RivetHTTPClient"),
      ]
    ),
    .testTarget(
      name: "InboxSearchTests",
      dependencies: [
        "InboxSearch",
        .product(name: "GitHubIntegration", package: "Rivet"),
        .product(name: "RivetPRInbox", package: "Rivet"),
        .product(name: "RivetHTTPClient", package: "RivetHTTPClient"),
      ]
    ),
  ],
  swiftLanguageModes: [.v6]
)
