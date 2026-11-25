// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "Rivet",
  platforms: [.macOS(.v15)],
  products: [
    .library(name: "RivetPRInbox", targets: ["RivetPRInbox"]),
    .library(name: "RivetPRInboxGitHub", targets: ["RivetPRInboxGitHub"]),
    .library(name: "RivetPRReader", targets: ["RivetPRReader"]),
    .library(name: "RivetPRReaderWebViewBridge", targets: ["RivetPRReaderWebViewBridge"]),
    .library(name: "RivetPRReaderHarnessRuntime", targets: ["RivetPRReaderHarnessRuntime"]),
    .executable(name: "RivetPRReaderHarness", targets: ["RivetPRReaderHarness"]),
    .library(name: "GitHubIntegration", targets: ["GitHubIntegration"]),
    .library(name: "RivetPresentation", targets: ["RivetPresentation"]),
    .executable(name: "RivetLoginDemo", targets: ["RivetLoginDemo"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apollographql/apollo-ios.git", exact: "2.1.2"),
    .package(path: "packages/RivetHTTPClient"),
  ],
  targets: [
    .target(
      name: "RivetPRInbox",
      path: "Sources/BoundedContexts/PRInbox"
    ),
    .target(
      name: "RivetPRInboxGitHub",
      dependencies: [
        "RivetPRInbox",
        "GitHubIntegration",
        .product(name: "RivetHTTPClient", package: "RivetHTTPClient"),
      ],
      path: "Sources/PRInboxGitHub"
    ),
    .target(
      name: "RivetRepositoryPullRequestsGitHub",
      dependencies: [
        "GitHubIntegration",
        .product(name: "RivetHTTPClient", package: "RivetHTTPClient"),
      ],
      path: "Sources/RivetRepositoryPullRequestsGitHub"
    ),
    .target(
      name: "RivetPRReader",
      path: "Sources/BoundedContexts/PRReader/Core"
    ),
    .target(
      name: "RivetPRReaderGitHub",
      dependencies: [
        "RivetPRReader",
        "GitHubIntegration",
        .product(name: "RivetHTTPClient", package: "RivetHTTPClient"),
      ],
      path: "Sources/BoundedContexts/PRReader/Infra/GitHub/REST"
    ),
    .target(
      name: "RivetPRReaderPresentation",
      dependencies: ["RivetPRReader"],
      path: "Sources/RivetPRReaderPresentation"
    ),
    .target(
      name: "RivetPRReaderComposition",
      dependencies: [
        "RivetPRReaderPresentation",
        "RivetPRReader",
        "RivetPRReaderGitHub",
        "GitHubIntegration",
      ],
      path: "Sources/RivetPRReaderComposition"
    ),
    .target(
      name: "RivetPRReaderWebViewBridge",
      dependencies: ["RivetPRReader"],
      path: "Sources/PRReaderWebViewBridge"
    ),
    .target(
      name: "RivetPRReaderHarnessRuntime",
      dependencies: ["RivetPRReader", "RivetPRReaderWebViewBridge"],
      path: "experiments/E012/Sources/RivetPRReaderHarnessRuntime",
      resources: [.process("Resources")]
    ),
    .executableTarget(
      name: "RivetPRReaderHarness",
      dependencies: ["RivetPRReaderHarnessRuntime"],
      path: "experiments/E012/Sources/RivetPRReaderHarness"
    ),
    .target(
      name: "GitHubIntegration",
      dependencies: [
        .product(name: "Apollo", package: "apollo-ios"),
        .product(name: "ApolloAPI", package: "apollo-ios"),
        .product(name: "RivetHTTPClient", package: "RivetHTTPClient"),
      ],
      path: "Sources/BoundedContexts/GitHubIntegration"
    ),
    .target(
      name: "RivetPresentation",
      dependencies: [],
      path: "Sources/Presentation",
      resources: [.process("Resources")]
    ),
    .target(
      name: "RivetLoginDemoRuntime",
      dependencies: ["RivetPresentation"],
      path: "experiments/E011/Sources/RivetLoginDemoRuntime"
    ),
    .executableTarget(
      name: "RivetLoginDemo",
      dependencies: ["RivetLoginDemoRuntime"],
      path: "experiments/E011/Sources/RivetLoginDemo"
    ),
    .testTarget(
      name: "RivetLoginDemoRuntimeTests",
      dependencies: ["RivetLoginDemoRuntime", "RivetPresentation"],
      path: "experiments/E011/Tests/RivetLoginDemoRuntimeTests"
    ),
    .testTarget(
      name: "RivetPRInboxTests",
      dependencies: ["RivetPRInbox"]
    ),
    .testTarget(
      name: "RivetPRInboxGitHubTests",
      dependencies: [
        "GitHubIntegration",
        "RivetPRInbox",
        "RivetPRInboxGitHub",
        .product(name: "RivetHTTPClient", package: "RivetHTTPClient"),
      ]
    ),
    .testTarget(
      name: "RivetRepositoryPullRequestsGitHubTests",
      dependencies: [
        "RivetRepositoryPullRequestsGitHub",
        "GitHubIntegration",
        .product(name: "RivetHTTPClient", package: "RivetHTTPClient"),
      ]
    ),
    .testTarget(
      name: "RivetPRReaderTests",
      dependencies: ["RivetPRReader"]
    ),
    .testTarget(
      name: "RivetPRReaderGitHubTests",
      dependencies: [
        "RivetPRReaderGitHub",
        "RivetPRReader",
        "GitHubIntegration",
        .product(name: "RivetHTTPClient", package: "RivetHTTPClient"),
      ]
    ),
    .testTarget(
      name: "RivetPRReaderPresentationTests",
      dependencies: ["RivetPRReaderPresentation", "RivetPRReader"]
    ),
    .testTarget(
      name: "RivetPRReaderCompositionTests",
      dependencies: [
        "RivetPRReaderComposition",
        "RivetPRReaderPresentation",
        "RivetPRReader",
        "GitHubIntegration",
        .product(name: "RivetHTTPClient", package: "RivetHTTPClient"),
      ]
    ),
    .testTarget(
      name: "RivetPRReaderWebViewBridgeTests",
      dependencies: ["RivetPRReaderWebViewBridge", "RivetPRReader"],
      path: "Tests/RivetPRReaderWebViewBridgeTests"
    ),
    .testTarget(
      name: "RivetPRReaderHarnessRuntimeTests",
      dependencies: ["RivetPRReaderHarnessRuntime", "RivetPRReader", "RivetPRReaderWebViewBridge"],
      path: "experiments/E012/Tests/RivetPRReaderHarnessRuntimeTests"
    ),
    .testTarget(
      name: "GitHubIntegrationTests",
      dependencies: [
        "GitHubIntegration",
        .product(name: "Apollo", package: "apollo-ios"),
        .product(name: "ApolloAPI", package: "apollo-ios"),
        .product(name: "RivetHTTPClient", package: "RivetHTTPClient"),
      ]
    ),
    .testTarget(
      name: "RivetPresentationTests",
      dependencies: ["RivetPresentation"],
      path: "Tests/RivetPresentationTests"
    ),
  ],
  swiftLanguageModes: [.v6]
)
