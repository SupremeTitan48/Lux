// swift-tools-version: 6.0
// The 1662 Book of Common Prayer tradition package: calendar, rules and the
// structured texts generated from the source witness by
// Tools/ContentExtraction. No UI framework dependencies.

import PackageDescription

let package = Package(
    name: "BCP1662",
    platforms: [.iOS(.v17), .macOS(.v14), .watchOS(.v10), .visionOS(.v1)],
    products: [
        .library(name: "BCP1662", targets: ["BCP1662"]),
    ],
    dependencies: [
        .package(path: "../../Packages/LuxCore"),
    ],
    targets: [
        .target(
            name: "BCP1662",
            dependencies: [.product(name: "LuxCore", package: "LuxCore")],
            resources: [.copy("Resources/Content")]
        ),
        .testTarget(
            name: "BCP1662Tests",
            dependencies: ["BCP1662"],
            exclude: ["Golden"]
        ),
    ]
)
