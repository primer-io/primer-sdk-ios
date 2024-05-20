// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "PrimerSDK",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "PrimerSDK",
            targets: ["PrimerSDK"]
        )
    ],
    dependencies: [
        .package(name: "PrimerNolPaySDK", path: "../primer-nol-pay-sdk-ios"),
        .package(url: "https://github.com/primer-io/primer-klarna-sdk-ios", from: "1.1.0")
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
                .byName(name: "PrimerSDK"),
                .byName(name: "PrimerNolPaySDK"),
                .product(name: "PrimerKlarnaSDK", package: "primer-klarna-sdk-ios")
            ],
            path: "Tests/Unit Tests"
        )
    ],
    swiftLanguageVersions: [.v5]
)
