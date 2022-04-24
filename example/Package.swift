// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "MyApplication",
    platforms: [.macOS(.v12)],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor", from: "4.57.0"),
    ],
    targets: [
        .target(name: "APIDefinition"),
        .target(
            name: "Service",
            dependencies: [
                "APIDefinition",
            ]
        ),
        .executableTarget(
            name: "Server",
            dependencies: [
                "Service",
                .product(name: "Vapor", package: "vapor"),
            ]
        ),
        .executableTarget(
            name: "Client",
            dependencies: [
                "APIDefinition",
            ]
        ),
    ]
)
