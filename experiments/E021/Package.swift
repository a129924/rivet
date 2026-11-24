// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "E021TransportCancellation",
  platforms: [.macOS(.v15)],
  dependencies: [.package(path: "../../packages/RivetHTTPClient")],
  targets: [
    .executableTarget(
      name: "TransportCancellationProbe",
      dependencies: [.product(name: "RivetHTTPClient", package: "RivetHTTPClient")])
  ],
  swiftLanguageModes: [.v6]
)
