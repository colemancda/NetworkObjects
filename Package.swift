// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "NetworkObjects",
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
