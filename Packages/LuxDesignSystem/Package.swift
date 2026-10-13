// swift-tools-version: 6.0
// LuxDesignSystem: design tokens (platform-neutral) and their SwiftUI
// bindings (compiled only where SwiftUI is available).

import PackageDescription

let package = Package(
    name: "LuxDesignSystem",
    platforms: [.iOS(.v17), .macOS(.v14), .watchOS(.v10), .visionOS(.v1)],
    products: [
        .library(name: "LuxDesignSystem", targets: ["LuxDesignSystem"]),
    ],
    targets: [
        .target(name: "LuxDesignSystem"),
        .testTarget(name: "LuxDesignSystemTests", dependencies: ["LuxDesignSystem"]),
    ]
)
