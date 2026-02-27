// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "PrimerSDK",
    defaultLocalization: "en",
    platforms: [
        .iOS("13.1")
    ],
    products: [
        .library(
            name: "PrimerSDK",
            targets: ["PrimerSDK"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/primer-io/primer-sdk-3ds-ios", from: "2.4.1"),
        .package(path: "Packages/PrimerFoundation"),
        .package(path: "Packages/PrimerCore"),
        .package(path: "Packages/PrimerNetworking"),
        .package(path: "Packages/PrimerUI")
    ],
    targets: [
        .target(
            name: "PrimerSDK",
            dependencies: [
                .product(name: "Primer3DS", package: "primer-sdk-3ds-ios"),
                .product(name: "PrimerFoundation", package: "PrimerFoundation"),
                .product(name: "PrimerCore", package: "PrimerCore"),
                .product(name: "PrimerNetworking", package: "PrimerNetworking"),
                .product(name: "PrimerUI", package: "PrimerUI")
            ],
            path: "Sources/PrimerSDK",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "Tests",
            dependencies: [
                .product(name: "Primer3DS", package: "primer-sdk-3ds-ios"),
                .byName(name: "PrimerSDK")
            ],
            path: "Tests/",
            sources: [
                "3DS/",
                "Utilities/"
            ]
        )
    ],
    swiftLanguageVersions: [.v5]
)
