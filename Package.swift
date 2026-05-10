// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "LookInsidePrivateDiscriminator",
    platforms: [
        .iOS(.v15),
        .macOS(.v13),
    ],
    products: [
        .library(
            name: "LookInsidePrivateDiscriminator",
            targets: ["LookInsidePrivateDiscriminator"]
        ),
    ],
    targets: [
        .target(name: "LookInsidePrivateDiscriminator"),
        .testTarget(
            name: "LookInsidePrivateDiscriminatorTests",
            dependencies: ["LookInsidePrivateDiscriminator"]
        ),
    ]
)
