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
        .library(
            name: "NetworkObjectsUI",
            targets: ["NetworkObjectsUI"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/PureSwift/CoreModel.git",
            branch: "master"
        )
    ],
    targets: [
        .target(
            name: "NetworkObjects",
            dependencies: [
                .product(
                    name: "CoreModel",
                    package: "CoreModel"
                )
            ]
        ),
        .target(
            name: "NetworkObjectsUI",
            dependencies: [
                "NetworkObjects"
            ]
        ),
        .testTarget(
            name: "NetworkObjectsTests",
            dependencies: ["NetworkObjects"]
        )
    ]
)
