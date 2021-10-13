// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "NodeBridge",
    products: [
        .library(
            name: "NodeBridge",
            targets: [
                "NodeBridge",
                "Bridge",
            ]),
    ],
    dependencies: [
        .package(url: "https://github.com/kewlbear/nodejs-ios.git", .branch("main")),
    ],
    targets: [
        .target(
            name: "NodeBridge",
            dependencies: ["nodejs-ios"]),
        .target(
            name: "Bridge",
            dependencies: [
                "nodejs-ios",
                "NodeBridge",
            ]),
        .testTarget(
            name: "NodeBridgeTests",
            dependencies: ["NodeBridge"]),
    ]
)
