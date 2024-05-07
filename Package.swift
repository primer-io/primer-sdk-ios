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
            targets: [
                "PrimerSDK",
                "PromiseKit"
            ]
        )
    ],
    targets: [
        .target(
            name: "PrimerSDK",
            dependencies: [
                .target(name: "PromiseKit")
            ],
            path: "Sources/PrimerSDK"
        ),
        .target(
            name: "PromiseKit",
            path: "Sources/PromiseKit",
            resources: [
                .process("Resources"),
                .copy("PromiseKit/LICENSE")
            ]
        ),
        .testTarget(
            name: "PrimerSDKTests",
            dependencies: [
                .byName(name: "PrimerSDK")
            ],
            path: "Tests/Unit Tests"
        )
    ],
    swiftLanguageVersions: [.v5]
)
