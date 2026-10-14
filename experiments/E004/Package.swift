// swift-tools-version: 6.1
import PackageDescription

let package = Package(
  name: "OAuthSQLiteExperiment",
  platforms: [.macOS(.v15)],
  products: [.executable(name: "oauth-sqlite-probe", targets: ["OAuthSQLiteProbe"])],
  dependencies: [
    .package(name: "Rivet", path: "../.."),
    .package(url: "https://github.com/groue/GRDB.swift.git", exact: "7.11.1"),
  ],
  targets: [
    .target(
      name: "SQLiteProbeCore",
      dependencies: [
        .product(name: "GitHubIntegration", package: "Rivet"),
        .product(name: "GRDB", package: "GRDB.swift"),
      ]),
    .executableTarget(name: "OAuthSQLiteProbe", dependencies: ["SQLiteProbeCore"]),
    .testTarget(name: "SQLiteProbeCoreTests", dependencies: ["SQLiteProbeCore"]),
  ],
  swiftLanguageModes: [.v6]
)
