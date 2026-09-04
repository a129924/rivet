// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Rivet",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "RivetPRInbox", targets: ["RivetPRInbox"])
    ],
    targets: [
        .target(
            name: "RivetPRInbox",
            path: "Sources/BoundedContexts/PRInbox"
        ),
        .testTarget(
            name: "RivetPRInboxTests",
            dependencies: ["RivetPRInbox"]
        )
    ],
    swiftLanguageModes: [.v6]
)
