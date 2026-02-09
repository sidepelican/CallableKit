// swift-tools-version: 5.10

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "CallableKit",
    platforms: [
        .macOS(.v14),
        .iOS(.v15),
        .tvOS(.v13),
        .watchOS(.v6),
        .macCatalyst(.v15),
    ],
    products: [
        .library(name: "CallableKit", targets: ["CallableKit"]),
        .library(name: "CallableKitURLSessionStub", targets: ["CallableKitURLSessionStub"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", "600.0.0"..<"999.0.0"),
    ],
    targets: [
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
        .testTarget(
            name: "CallableKitMacrosTests",
            dependencies: [
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
                "CallableKitMacros",
            ]
        ),
        .target(
            name: "CallableKitURLSessionStub",
            dependencies: [
                "CallableKit",
            ]
        ),
    ]
)
