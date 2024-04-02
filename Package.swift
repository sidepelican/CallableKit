// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "CallableKit",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "codegen", targets: ["Codegen"]),
        .library(name: "CallableKit", targets: ["CallableKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.2"),
        .package(url: "https://github.com/omochi/CodableToTypeScript", from: "2.11.0"),
        .package(url: "https://github.com/omochi/SwiftTypeReader", from: "2.8.0"),
    ],
    targets: [
        .executableTarget(
            name: "Codegen",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "CallableKit"
            ]
        ),
        .target(
            name: "CallableKit",
            dependencies: [
                "CodableToTypeScript",
                "SwiftTypeReader"
            ],
            swiftSettings: [
                .enableUpcomingFeature("BareSlashRegexLiterals"),
            ]
        )
    ]
)
