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
        .package(url: "https://github.com/primer-io/primer-sdk-3ds-ios", from: "2.3.1"),
        .package(url: "https://github.com/primer-io/primer-klarna-sdk-ios", from: "1.1.1"),
        .package(url: "https://github.com/primer-io/primer-nol-pay-sdk-ios", from: "1.0.2"),
        .package(url: "https://github.com/primer-io/primer-stripe-sdk-ios", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "PrimerSDK",
            dependencies: [
                .product(name: "Primer3DS", package: "primer-sdk-3ds-ios"),
                .product(name: "PrimerKlarnaSDK", package: "primer-klarna-sdk-ios"),
                .product(name: "PrimerNolPaySDK", package: "primer-nol-pay-sdk-ios"),
                .product(name: "PrimerStripeSDK", package: "primer-stripe-sdk-ios")
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
                .product(name: "PrimerKlarnaSDK", package: "primer-klarna-sdk-ios"),
                .product(name: "PrimerNolPaySDK", package: "primer-nol-pay-sdk-ios"),
                .product(name: "PrimerStripeSDK", package: "primer-stripe-sdk-ios"),
                .byName(name: "PrimerSDK")
            ],
            path: "Tests/"
        )
    ],
    swiftLanguageVersions: [.v5]
)
