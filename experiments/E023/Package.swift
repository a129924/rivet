// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "E023AsyncRequestLifecycle",
  platforms: [.macOS(.v15)],
  products: [
    .executable(name: "async-lifecycle-probe", targets: ["AsyncLifecycleCLI"])
  ],
  targets: [
    .target(name: "AsyncLifecycleProbe"),
    .executableTarget(name: "AsyncLifecycleCLI", dependencies: ["AsyncLifecycleProbe"]),
    .testTarget(name: "AsyncLifecycleProbeTests", dependencies: ["AsyncLifecycleProbe"]),
  ],
  swiftLanguageModes: [.v6]
)
