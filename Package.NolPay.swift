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
            targets: ["PrimerSDK", "PrimerNolPaySDK"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/primer-io/primer-nol-pay-sdk-ios", from: "1.0.2")
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
        .testTarget(
            name: "PrimerSDKTests",
            dependencies: [
                .product(name: "PrimerNolPaySDK", package: "primer-nol-pay-sdk-ios"),
                .byName(name: "PrimerSDK")
            ],
            path: "Tests/Unit Tests"
        )
    ],
    swiftLanguageVersions: [.v5]
)
