// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "InboxI1Verification",
  platforms: [.macOS(.v15)],
  dependencies: [.package(name: "Rivet", path: "../..")],
  targets: [
    .executableTarget(
      name: "InboxI1Verification",
      dependencies: [.product(name: "RivetPresentation", package: "Rivet")]
    ),
    .testTarget(
      name: "InboxI1VerificationTests",
      dependencies: ["InboxI1Verification"]
    ),
  ]
)
