// swift-tools-version: 6.0
// LuxCore: the platform-independent liturgical core. No UI framework
// dependencies; Foundation only.

import PackageDescription

let package = Package(
    name: "LuxCore",
    platforms: [.iOS(.v17), .macOS(.v14), .watchOS(.v10), .visionOS(.v1)],
    products: [
        .library(name: "LuxCore", targets: ["LuxCore"]),
    ],
    targets: [
        .target(name: "LuxCore"),
        .testTarget(name: "LuxCoreTests", dependencies: ["LuxCore"]),
    ]
)
