// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Rivet",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "RivetPRInbox", targets: ["RivetPRInbox"]),
        .library(name: "RivetPRReader", targets: ["RivetPRReader"]),
        .library(name: "RivetPRReaderWebViewBridge", targets: ["RivetPRReaderWebViewBridge"]),
        .library(name: "RivetPRReaderHarnessRuntime", targets: ["RivetPRReaderHarnessRuntime"]),
        .executable(name: "RivetPRReaderHarness", targets: ["RivetPRReaderHarness"]),
        .library(name: "GitHubIntegration", targets: ["GitHubIntegration"]),
        .library(name: "RivetPresentation", targets: ["RivetPresentation"])
    ],
    dependencies: [
        .package(url: "https://github.com/apollographql/apollo-ios.git", exact: "2.1.2")
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
            name: "RivetPRReaderHarnessRuntime",
            dependencies: ["RivetPRReader", "RivetPRReaderWebViewBridge"],
            path: "Sources/RivetPRReaderHarnessRuntime",
            resources: [.process("Resources")]
        ),
        .executableTarget(
            name: "RivetPRReaderHarness",
            dependencies: ["RivetPRReaderHarnessRuntime"],
            path: "Sources/RivetPRReaderHarness"
        ),
        .target(
            name: "GitHubIntegration",
            dependencies: [
                .product(name: "Apollo", package: "apollo-ios"),
                .product(name: "ApolloAPI", package: "apollo-ios")
            ],
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
            name: "RivetPRReaderHarnessRuntimeTests",
            dependencies: ["RivetPRReaderHarnessRuntime", "RivetPRReader", "RivetPRReaderWebViewBridge"],
            path: "Tests/RivetPRReaderHarnessRuntimeTests"
        ),
        .testTarget(
            name: "GitHubIntegrationTests",
            dependencies: [
                "GitHubIntegration",
                .product(name: "Apollo", package: "apollo-ios"),
                .product(name: "ApolloAPI", package: "apollo-ios")
            ]
        ),
        .testTarget(
            name: "RivetPresentationTests",
            dependencies: ["RivetPresentation"],
            path: "Tests/RivetPresentationTests"
        )
    ],
    swiftLanguageModes: [.v6]
)
