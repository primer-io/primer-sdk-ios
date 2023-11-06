// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "PrimerSDK",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v10)
    ],
    products: [
        .library(
            name: "PrimerSDK",
            targets: ["PrimerSDK"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/primer-io/primer-klarna-sdk-ios.git",
            .branchItem("feature/klarnamobilesdk_v2")
        )
    ],
    targets: [
        .target(
            name: "PrimerSDK",
            dependencies: [
                .product(name: "PrimerKlarnaSDK", package: "primer-klarna-sdk-ios")
            ],
            path: "Sources/PrimerSDK",
            resources: [
                .process("Resources"),
                .copy("Classes/Third Party/PromiseKit/LICENSE")
            ]
        )
    ],
    swiftLanguageVersions: [.v4_2]
)
