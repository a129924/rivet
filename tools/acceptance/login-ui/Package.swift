// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "RivetLoginAcceptance",
  platforms: [.macOS(.v15)],
  products: [.executable(name: "RivetLoginAcceptance", targets: ["RivetLoginAcceptance"])],
  dependencies: [.package(name: "Rivet", path: "../../..")],
  targets: [
    .target(
      name: "RivetLoginAcceptanceSupport",
      dependencies: [.product(name: "RivetPresentation", package: "Rivet")]
    ),
    .executableTarget(name: "RivetLoginAcceptance", dependencies: ["RivetLoginAcceptanceSupport"]),
    .testTarget(
      name: "RivetLoginAcceptanceSupportTests",
      dependencies: [
        "RivetLoginAcceptanceSupport", .product(name: "RivetPresentation", package: "Rivet"),
      ]
    ),
  ],
  swiftLanguageModes: [.v6]
)
