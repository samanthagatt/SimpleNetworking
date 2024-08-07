// swift-tools-version: 5.10
// TODO: Change tools version to 6 when Swift v6 officially comes out
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SimpleNetworking",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SimpleNetworking",
            targets: ["SimpleNetworking"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SimpleNetworking"),
        .testTarget(
            name: "SimpleNetworkingTests",
            dependencies: ["SimpleNetworking"]),
    ]
)
