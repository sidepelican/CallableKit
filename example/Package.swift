// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "MyApplication",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(path: "../"),
        .package(url: "https://github.com/vapor/vapor", from: "4.57.0"),
    ],
    targets: [
        .target(
            name: "APIDefinition",
            dependencies: ["OtherDependency"]
        ),
        .target(name: "OtherDependency"),
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
            ],
            swiftSettings: [
                .unsafeFlags(["-strict-concurrency=complete"]),
            ]
        ),
        .executableTarget(
            name: "Client",
            dependencies: [
                "APIDefinition",
            ],
            swiftSettings: [
                .unsafeFlags(["-strict-concurrency=complete"]),
            ]
        ),
        .plugin(
            name: "CodegenPlugin",
            capability: .command(
                intent: .custom(verb: "codegen", description: "Generate codes from Sources/APIDefinition"),
                permissions: [.writeToPackageDirectory(reason: "Place generated code")]
            ),
            dependencies: [
                .product(name: "codegen", package: "CallableKit"),
            ]
        )
    ]
)
