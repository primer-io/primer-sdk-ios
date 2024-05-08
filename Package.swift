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
                "PrimerPromiseKit"
            ]
        )
    ],
    targets: [
        .target(
            name: "PrimerSDK",
            dependencies: [
                .target(name: "PrimerPromiseKit")
            ],
            path: "Sources/PrimerSDK",
            resources: [
                .process("Resources")
            ]
        ),
        .target(
            name: "PrimerPromiseKit",
            path: "Sources/PromiseKit",
            resources: [
                .copy("PromiseKit/LICENSE")
            ]
        ),
        .testTarget(
            name: "PrimerSDKTests",
            dependencies: [
                .byName(name: "PrimerSDK"),
                .byName(name: "PrimerPromiseKit")
            ],
            path: "Tests/Unit Tests"
        )
    ],
    swiftLanguageVersions: [.v5]
)
