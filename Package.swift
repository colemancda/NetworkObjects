// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "NetworkObjects",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .watchOS(.v6),
        .tvOS(.v13),
    ],
    products: [
        .library(
            name: "NetworkObjects",
            targets: ["NetworkObjects"]
        ),
    ],
    targets: [
        .target(
            name: "NetworkObjects"),
        .testTarget(
            name: "NetworkObjectsTests",
            dependencies: ["NetworkObjects"]
        )
    ]
)
