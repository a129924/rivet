// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Rivet",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "RivetPRInbox", targets: ["RivetPRInbox"]),
        .library(name: "GitHubIntegration", targets: ["GitHubIntegration"])
    ],
    targets: [
        .target(
            name: "RivetPRInbox",
            path: "Sources/BoundedContexts/PRInbox"
        ),
        .target(
            name: "GitHubIntegration",
            path: "Sources/BoundedContexts/GitHubIntegration"
        ),
        .testTarget(
            name: "RivetPRInboxTests",
            dependencies: ["RivetPRInbox"]
        ),
        .testTarget(
            name: "GitHubIntegrationTests",
            dependencies: ["GitHubIntegration"]
        )
    ],
    swiftLanguageModes: [.v6]
)
