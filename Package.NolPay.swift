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
        .package(url: "https://github.com/primer-io/primer-nol-pay-sdk-ios", from: "1.0.2"),
        .package(path: "Packages/PrimerFoundation"),
        .package(path: "Packages/PrimerCore"),
        .package(path: "Packages/PrimerNetworking")
    ],
    targets: [
        .target(
            name: "PrimerSDK",
            dependencies: [
                .product(name: "PrimerNolPaySDK", package: "primer-nol-pay-sdk-ios"),
                .product(name: "PrimerFoundation", package: "PrimerFoundation"),
                .product(name: "PrimerCore", package: "PrimerCore"),
                .product(name: "PrimerNetworking", package: "PrimerNetworking")
            ],
            path: "Sources/PrimerSDK",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "Tests",
            dependencies: [
                .product(name: "PrimerNolPaySDK", package: "primer-nol-pay-sdk-ios"),
                .byName(name: "PrimerSDK")
            ],
            path: "Tests/",
            sources: [
                "NolPay/",
                "Utilities/"
            ]
        )
    ],
    swiftLanguageVersions: [.v5]
)
