// swift-tools-version: 5.10

import PackageDescription

func swiftSettings() -> [SwiftSetting] {
    return [
        .enableUpcomingFeature("ForwardTrailingClosures"),
        .enableUpcomingFeature("ConciseMagicFile"),
        .enableUpcomingFeature("BareSlashRegexLiterals"),
        .enableUpcomingFeature("IsolatedDefaultValues"),
        .enableUpcomingFeature("DeprecateApplicationMain"),
        .enableUpcomingFeature("GlobalConcurrency"),
        .enableUpcomingFeature("DynamicActorIsolation"),
//        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("DisableOutwardActorInference"),
        .enableUpcomingFeature("ImportObjcForwardDeclarations"),
        .enableUpcomingFeature("GlobalActorIsolatedTypesUsability"),
        .enableUpcomingFeature("MemberImportVisibility"),
//        .enableUpcomingFeature("InferSendableFromCaptures"),
        .enableUpcomingFeature("RegionBasedIsolation"),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("StrictConcurrency"),
    ]
}

let package = Package(
    name: "MyApplication",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(path: "../"),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.106.7"),
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.5.0"),
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
            name: "VaporServer",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                "Service",
            ],
            swiftSettings: swiftSettings()
        ),
        .executableTarget(
            name: "HBServer",
            dependencies: [
                .product(name: "Hummingbird", package: "hummingbird"),
                "Service",
            ],
            swiftSettings: swiftSettings()
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
