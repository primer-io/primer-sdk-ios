// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "PrimerSDK",
    defaultLocalization: "en",
    platforms: [.iOS("13.1")],
    products: [
        .library(name: "PrimerSDK", targets: ["PrimerSDK"]),
        .library(name: "PrimerSDK3DS", targets: ["PrimerSDK3DS"]),
        .library(name: "PrimerSDKKlarna",targets: ["PrimerSDKKlarna"]),
        .library(name: "PrimerSDKNolPay",  targets: ["PrimerSDKNolPay"]),
        .library(name: "PrimerSDKStripe",  targets: ["PrimerSDKStripe"]),
    ],
    dependencies: [
        .package(url: "https://github.com/primer-io/primer-sdk-3ds-ios", from: "2.4.4"),
        .package(url: "https://github.com/primer-io/primer-klarna-sdk-ios", from: "1.1.1"),
        .package(url: "https://github.com/primer-io/primer-nol-pay-sdk-ios", from: "1.0.2"),
        .package(url: "https://github.com/primer-io/primer-stripe-sdk-ios", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "PrimerSDK",
            path: "Sources/PrimerSDK",
            resources: [
                .process("Resources"),
                .copy("Classes/Third Party/PromiseKit/LICENSE")
            ]
        ),
        .target(
            name: "PrimerSDK3DS",
            dependencies: [.product(name: "Primer3DS", package: "primer-sdk-3ds-ios")],
            path: "PrimerSDK3DS"
        ),
        .target(
            name: "PrimerSDKKlarna",
            dependencies: [.product(name: "PrimerKlarnaSDK", package: "primer-klarna-sdk-ios")],
            path: "PrimerSDKKlarna",
        ),
        .target(
            name: "PrimerSDKNolPay",
            dependencies: [.product(name: "PrimerNolPaySDK", package: "primer-nol-pay-sdk-ios")],
            path: "PrimerSDKNolPay",
        ),
        .target(
            name: "PrimerSDKStripe",
            dependencies: [.product(name: "PrimerStripeSDK", package: "primer-stripe-sdk-ios")],
            path: "PrimerSDKStripe"
        ),
        .testTarget(
            name: "Tests",
            dependencies: [
                .product(name: "Primer3DS", package: "primer-sdk-3ds-ios"),
                .byName(name: "PrimerSDK")
            ],
            path: "Tests/",
            sources: ["3DS/", "Utilities/", "Primer/"]
        )
    ],
    swiftLanguageVersions: [.v5]
)
