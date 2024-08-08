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
        .package(url: "git@github.com:primer-io/primer-stripe-sdk-ios", .branch("nq/initial_setup"))
    ],
    targets: [
        .target(
            name: "PrimerSDK",
            dependencies: [
                .product(name: "PrimerStripeSDK", package: "primer-stripe-sdk-ios")
            ],
            path: "Sources/PrimerSDK",
            resources: [
                .process("Resources"),
                .copy("Classes/Third Party/PromiseKit/LICENSE")
            ]
        ),
        .testTarget(
            name: "Tests",
            dependencies: [
                .product(name: "PrimerStripeSDK", package: "primer-stripe-sdk-ios"),
                .byName(name: "PrimerSDK")
            ],
            path: "Tests/",
            sources: [
                "Stripe/",
                "Utilities/"
            ]
        )
    ],
    swiftLanguageVersions: [.v5]
)
