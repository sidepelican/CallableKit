// swift-tools-version: 5.10

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "CallableKit",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "codegen", targets: ["Codegen"]),
        .library(name: "CallableKit", targets: ["CallableKit"]),
        .library(name: "CallableKitVaporTransport", targets: ["CallableKitVaporTransport"]),
        .library(name: "CallableKitHummingbirdTransport", targets: ["CallableKitHummingbirdTransport"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.2"),
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.1"),
        .package(url: "https://github.com/omochi/CodableToTypeScript.git", from: "3.0.1"),
        .package(url: "https://github.com/omochi/SwiftTypeReader.git", from: "3.1.0"),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.106.7"),
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.5.0"),
    ],
    targets: [
        .executableTarget(
            name: "Codegen",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "CodegenImpl",
            ]
        ),
        .target(
            name: "CodegenImpl",
            dependencies: [
                "CodableToTypeScript",
                "SwiftTypeReader",
            ],
            swiftSettings: [
                .enableUpcomingFeature("BareSlashRegexLiterals"),
            ]
        ),
        .target(
            name: "CallableKit",
            dependencies: [
                "CallableKitMacros",
            ]
        ),
        .macro(
            name: "CallableKitMacros",
            dependencies: [
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftDiagnostics", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
            ]
        ),
        .target(
            name: "CallableKitVaporTransport",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                "CallableKit",
            ]
        ),
        .target(
            name: "CallableKitHummingbirdTransport",
            dependencies: [
                .product(name: "Hummingbird", package: "hummingbird"),
                "CallableKit",
            ]
        )
    ]
)
