// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "OAuthRedirectProbe",
  platforms: [.macOS(.v15)],
  products: [.executable(name: "oauth-redirect-probe", targets: ["OAuthRedirectProbe"])],
  targets: [
    .target(name: "ProbeCore"),
    .executableTarget(name: "OAuthRedirectProbe", dependencies: ["ProbeCore"]),
    .testTarget(name: "ProbeCoreTests", dependencies: ["ProbeCore"]),
  ]
)
