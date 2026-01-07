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
        .package(url: "https://github.com/primer-io/primer-klarna-sdk-ios", from: "1.3.1"),
        .package(path: "Packages/PrimerFoundation")
    ],
    targets: [
        .target(
            name: "PrimerSDK",
            dependencies: [
                .product(name: "PrimerKlarnaSDK", package: "primer-klarna-sdk-ios"),
                .product(name: "PrimerFoundation", package: "PrimerFoundation")
            ],
            path: "Sources/PrimerSDK",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "Tests",
            dependencies: [
                .product(name: "PrimerKlarnaSDK", package: "primer-klarna-sdk-ios"),
                .byName(name: "PrimerSDK")
            ],
            path: "Tests/",
            sources: [
                "Klarna/",
                "Utilities/"
            ]
        )
    ],
    swiftLanguageVersions: [.v5]
)
