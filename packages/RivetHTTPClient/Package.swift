// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "RivetHTTPClient",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "RivetHTTPClient", targets: ["RivetHTTPClient"])
    ],
    targets: [
        .target(name: "RivetHTTPClient"),
        .testTarget(
            name: "RivetHTTPClientTests",
            dependencies: ["RivetHTTPClient"]
        )
    ],
    swiftLanguageModes: [.v6]
)
