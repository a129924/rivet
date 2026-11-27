// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "InboxExperimentSupport",
  platforms: [.macOS(.v15)],
  products: [.library(name: "InboxExperimentSupport", targets: ["InboxExperimentSupport"])],
  dependencies: [.package(name: "Rivet", path: "../../..")],
  targets: [
    .target(
      name: "InboxExperimentSupport",
      dependencies: [.product(name: "RivetPresentation", package: "Rivet")]
    )
  ]
)
