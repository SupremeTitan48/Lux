// swift-tools-version: 6.0
// The King James Version as a Scripture provider for Lux: the text generated
// from the witness in Witness/ by Tools/ContentExtraction. Licensed and
// versioned separately from the liturgical traditions. No UI framework
// dependencies.

import PackageDescription

let package = Package(
    name: "LuxKJV",
    platforms: [.iOS(.v17), .macOS(.v14), .watchOS(.v10), .visionOS(.v1)],
    products: [
        .library(name: "LuxKJV", targets: ["LuxKJV"]),
    ],
    dependencies: [
        .package(path: "../../Packages/LuxCore"),
        // Tests only: every lesson the 1662 lectionary appoints must resolve.
        .package(path: "../../Traditions/BCP1662"),
    ],
    targets: [
        .target(
            name: "LuxKJV",
            dependencies: [.product(name: "LuxCore", package: "LuxCore")],
            resources: [.copy("Resources/Content")]
        ),
        .testTarget(
            name: "LuxKJVTests",
            dependencies: ["LuxKJV", .product(name: "BCP1662", package: "BCP1662")]
        ),
    ]
)
