// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "fs-app-configuration",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(name: "AppConfiguration", targets: ["AppConfiguration"]),
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.120.2"),
        // A Swift library for reading configuration in applications and libraries.
        .package(url: "https://github.com/apple/swift-configuration", from: "1.0.0"),
        // 📄 Swift-DocC plugin for generating documentation.
        .package(url: "https://github.com/apple/swift-docc-plugin.git", from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "AppConfiguration",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Configuration", package: "swift-configuration"),
            ]
        ),
        .testTarget(
            name: "AppConfigurationTests",
            dependencies: [
                .target(name: "AppConfiguration"),
                .product(name: "VaporTesting", package: "vapor"),
            ]
        ),
    ]
)
