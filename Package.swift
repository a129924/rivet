// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Rivet",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "RivetPRInbox", targets: ["RivetPRInbox"]),
        .library(name: "RivetPRReader", targets: ["RivetPRReader"]),
        .library(name: "RivetPRReaderWebViewBridge", targets: ["RivetPRReaderWebViewBridge"]),
        .library(name: "GitHubIntegration", targets: ["GitHubIntegration"]),
        .library(name: "RivetPresentation", targets: ["RivetPresentation"])
    ],
    targets: [
        .target(
            name: "RivetPRInbox",
            path: "Sources/BoundedContexts/PRInbox"
        ),
        .target(
            name: "RivetPRReader",
            path: "Sources/BoundedContexts/PRReader/Core"
        ),
        .target(
            name: "RivetPRReaderWebViewBridge",
            dependencies: ["RivetPRReader"],
            path: "Sources/PRReaderWebViewBridge"
        ),
        .target(
            name: "GitHubIntegration",
            path: "Sources/BoundedContexts/GitHubIntegration"
        ),
        .target(
            name: "RivetPresentation",
            dependencies: [],
            path: "Sources/Presentation"
        ),
        .testTarget(
            name: "RivetPRInboxTests",
            dependencies: ["RivetPRInbox"]
        ),
        .testTarget(
            name: "RivetPRReaderTests",
            dependencies: ["RivetPRReader"]
        ),
        .testTarget(
            name: "RivetPRReaderWebViewBridgeTests",
            dependencies: ["RivetPRReaderWebViewBridge", "RivetPRReader"],
            path: "Tests/RivetPRReaderWebViewBridgeTests"
        ),
        .testTarget(
            name: "GitHubIntegrationTests",
            dependencies: ["GitHubIntegration"]
        ),
        .testTarget(
            name: "RivetPresentationTests",
            dependencies: ["RivetPresentation"],
            path: "Tests/RivetPresentationTests"
        )
    ],
    swiftLanguageModes: [.v6]
)
