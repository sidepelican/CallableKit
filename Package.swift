// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "CallableKit",
    platforms: [.macOS(.v12)],
    products: [
        .executable(name: "codegen", targets: ["Codegen"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.1.0"),
        .package(url: "https://github.com/omochi/CodableToTypeScript", from: "2.1.0"),
        .package(url: "https://github.com/omochi/SwiftTypeReader", from: "2.1.0")
    ],
    targets: [
        .executableTarget(
            name: "Codegen",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "CodableToTypeScript",
                "SwiftTypeReader"
            ]
        ),
    ]
)
