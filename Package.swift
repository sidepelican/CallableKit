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
        .package(url: "https://github.com/omochi/CodableToTypeScript", branch: "str-2"),
        .package(url: "https://github.com/omochi/SwiftTypeReader", branch: "decl-repr"),
    ],
    targets: [
        .executableTarget(
            name: "Codegen",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "CodableToTypeScript",
                "SwiftTypeReader",
            ]
        ),
    ]
)
